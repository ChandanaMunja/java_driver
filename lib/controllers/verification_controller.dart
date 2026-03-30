import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jippydriver_driver/constant/constant.dart';
import 'package:jippydriver_driver/constant/show_toast_dialog.dart';
import 'package:jippydriver_driver/controllers/login_controller.dart';
import 'package:jippydriver_driver/models/document_model.dart';
import 'package:jippydriver_driver/models/driver_document_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VerificationController extends GetxController {
  static const Duration _httpTimeout = Duration(seconds: 45);

  RxBool isLoading = true.obs;
  RxBool isSubmittingIdentity = false.obs;
  /// Identity (Aadhaar + DL) saved on the server — fields lock and upload cards read-only.
  final RxBool isSubmitted = false.obs;
  final TextEditingController aadhaarNumberController =
      TextEditingController();
  final TextEditingController drivingLicenseController =
      TextEditingController();

  Timer? _identityDraftDebounce;

  /// O(1) lookups for template id → uploaded row (rebuilt when [driverDocumentList] changes).
  Map<String, Documents> _driverDocById = {};

  int get approvedCount {
    final templates = documentList;
    if (templates.isEmpty) return 0;
    final allowedIds = <String>{
      for (final t in templates)
        if ((t.id ?? '').isNotEmpty) t.id!,
    };
    if (allowedIds.isEmpty) return 0;
    var n = 0;
    for (final d in driverDocumentList) {
      final id = d.documentId;
      if (id != null &&
          allowedIds.contains(id) &&
          d.status == 'approved') {
        n++;
      }
    }
    return n;
  }

  double get verificationProgress {
    final total = documentList.length;
    if (total == 0) return 0;
    return approvedCount / total;
  }

  Documents findDocument(DocumentModel doc) {
    final id = doc.id;
    if (id == null || id.isEmpty) return Documents();
    return _driverDocById[id] ?? Documents();
  }

  void _reindexDriverDocuments() {
    _driverDocById = {
      for (final d in driverDocumentList)
        if ((d.documentId ?? '').isNotEmpty) d.documentId!: d,
    };
  }

  bool validateMandatoryFields() {
    final aadhaar = aadhaarNumberController.text.trim();
    final dl = drivingLicenseController.text.trim();
    if (aadhaar.isEmpty) {
      ShowToastDialog.showToast('Aadhaar number is required'.tr);
      return false;
    }
    if (dl.isEmpty) {
      ShowToastDialog.showToast('Driving license number is required'.tr);
      return false;
    }
    return true;
  }

  @override
  void onInit() {
    super.onInit();
    aadhaarNumberController.addListener(_schedulePersistIdentityDraft);
    drivingLicenseController.addListener(_schedulePersistIdentityDraft);
    getDocument();
  }

  void _schedulePersistIdentityDraft() {
    if (isSubmitted.value) return;
    _identityDraftDebounce?.cancel();
    _identityDraftDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(_persistIdentityDraft());
    });
  }

  Future<void> _persistIdentityDraft() async {
    if (isSubmitted.value) return;
    final uid = await LoginController.getFirebaseId();
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _draftBlobKey(uid),
      jsonEncode({
        'a': aadhaarNumberController.text,
        'd': drivingLicenseController.text,
      }),
    );
    await prefs.remove(_draftKeyLegacyAadhaar(uid));
    await prefs.remove(_draftKeyLegacyDl(uid));
  }

  Future<void> _restoreIdentityDraftIfEmpty() async {
    if (isSubmitted.value) return;
    final uid = await LoginController.getFirebaseId();
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    String? a;
    String? d;
    final blob = prefs.getString(_draftBlobKey(uid));
    if (blob != null && blob.isNotEmpty) {
      try {
        final m = jsonDecode(blob) as Map<String, dynamic>;
        a = m['a']?.toString();
        d = m['d']?.toString();
      } catch (_) {}
    }
    a ??= prefs.getString(_draftKeyLegacyAadhaar(uid));
    d ??= prefs.getString(_draftKeyLegacyDl(uid));

    if (aadhaarNumberController.text.trim().isEmpty &&
        (a ?? '').trim().isNotEmpty) {
      aadhaarNumberController.text = a!;
    }
    if (drivingLicenseController.text.trim().isEmpty &&
        (d ?? '').trim().isNotEmpty) {
      drivingLicenseController.text = d!;
    }
  }

  Future<void> _clearIdentityDraft() async {
    final uid = await LoginController.getFirebaseId();
    if (uid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftBlobKey(uid));
    await prefs.remove(_draftKeyLegacyAadhaar(uid));
    await prefs.remove(_draftKeyLegacyDl(uid));
  }

  static String _draftBlobKey(String uid) => 'verif_id_draft_$uid';
  static String _draftKeyLegacyAadhaar(String uid) =>
      'verif_id_draft_aadhaar_$uid';
  static String _draftKeyLegacyDl(String uid) => 'verif_id_draft_dl_$uid';

  @override
  void onClose() {
    _identityDraftDebounce?.cancel();
    aadhaarNumberController.removeListener(_schedulePersistIdentityDraft);
    drivingLicenseController.removeListener(_schedulePersistIdentityDraft);
    if (!isSubmitted.value) {
      unawaited(_persistIdentityDraft());
    }
    aadhaarNumberController.dispose();
    drivingLicenseController.dispose();
    super.onClose();
  }

  RxList<DocumentModel> documentList = <DocumentModel>[].obs;
  RxList<Documents> driverDocumentList = <Documents>[].obs;

  /// Refetch document templates and driver uploads. Use [silent] after inline actions
  /// (e.g. identity submit) to avoid a full-screen loading flash.
  ///
  /// [suppressDraftRestore]: set after identity POST so a lagging GET does not re-apply
  /// stale drafts over the values you just submitted.
  Future<void> getDocument({
    bool silent = false,
    bool suppressDraftRestore = false,
  }) async {
    if (!silent) {
      isLoading.value = true;
      update();
    }

    try {
      final listFuture =
          FireStoreUtils.getDocumentList().catchError((Object e, StackTrace _) {
        debugPrint('getDocumentList: $e');
        return <DocumentModel>[];
      });
      final driverFuture =
          FireStoreUtils.getDocumentOfDriver().catchError((Object e, StackTrace _) {
        debugPrint('getDocumentOfDriver: $e');
        return null;
      });

      documentList.value = await listFuture;
      final value = await driverFuture;

      if (value?.documents != null) {
        driverDocumentList.value = value!.documents!;
      } else {
        driverDocumentList.value = [];
      }
      _reindexDriverDocuments();

      if (value != null) {
        final serverA = (value.aadharNo ?? '').trim();
        final serverD = (value.drivingLicenseNumber ?? '').trim();
        isSubmitted.value = serverA.isNotEmpty && serverD.isNotEmpty;

        // Never replace typed draft with empty API values (common before submit).
        if (serverA.isNotEmpty) {
          aadhaarNumberController.text = value.aadharNo ?? serverA;
        }
        if (serverD.isNotEmpty) {
          drivingLicenseController.text = value.drivingLicenseNumber ?? serverD;
        }

        if (isSubmitted.value) {
          await _clearIdentityDraft();
        } else if (!suppressDraftRestore) {
          await _restoreIdentityDraftIfEmpty();
        }
      } else {
        isSubmitted.value = false;
        if (!suppressDraftRestore) {
          await _restoreIdentityDraftIfEmpty();
        }
      }
    } catch (e, st) {
      debugPrint('Error in getDocument: $e\n$st');
      if (!isSubmitted.value && !suppressDraftRestore) {
        await _restoreIdentityDraftIfEmpty();
      }
    } finally {
      if (!silent) {
        isLoading.value = false;
      }
      update();
    }
  }

  Future<bool> submitIdentityDetails() async {
    final aadhaar = aadhaarNumberController.text.trim();
    final drivingLicense = drivingLicenseController.text.trim();

    if (aadhaar.isEmpty) {
      ShowToastDialog.showToast("Aadhaar number is required");
      return false;
    }
    if (drivingLicense.isEmpty) {
      ShowToastDialog.showToast("Driving license number is required");
      return false;
    }

    isSubmittingIdentity.value = true;
    update();
    try {
      final userId = await LoginController.getFirebaseId();
      final response = await http
          .post(
        Uri.parse("${Constant.baseUrl}documents/driver/identity"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "user_id": userId,
          "aadhaar_number": aadhaar,
          "driving_license_number": drivingLicense,
        }),
      )
          .timeout(_httpTimeout);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['success'] == true) {
          await _clearIdentityDraft();
          await getDocument(silent: true, suppressDraftRestore: true);
          // Keep locked after POST even if GET lags before identity appears on server.
          isSubmitted.value = true;
          return true;
        }
        final msg = body['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          ShowToastDialog.showToast(msg);
        }
      } else {
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>?;
          final msg = body?['message']?.toString();
          if (msg != null && msg.isNotEmpty) {
            ShowToastDialog.showToast(msg);
          }
        } catch (_) {}
      }
    } on TimeoutException {
      ShowToastDialog.showToast(
          'Request timed out. Check your connection and try again.'.tr);
    } catch (e) {
      debugPrint("submitIdentityDetails error: $e");
      ShowToastDialog.showToast(
          'Could not submit. Please try again.'.tr);
    } finally {
      isSubmittingIdentity.value = false;
      update();
    }
    return false;
  }
}
