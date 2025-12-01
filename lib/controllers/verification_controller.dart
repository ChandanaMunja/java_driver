import 'package:get/get.dart';
import 'package:jippydriver_driver/models/document_model.dart';
import 'package:jippydriver_driver/models/driver_document_model.dart';
import 'package:jippydriver_driver/utils/fire_store_utils.dart';

class VerificationController extends GetxController {
  RxBool isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    getDocument();
    super.onInit();
  }

  RxList documentList = <DocumentModel>[].obs;
  RxList driverDocumentList = <Documents>[].obs;

  getDocument() async {
    isLoading.value = true;
    update();

    try {
      await FireStoreUtils.getDocumentList().then((value) {
        documentList.value = value;
      });

      await FireStoreUtils.getDocumentOfDriver().then((value) {
        if(value != null && value.documents != null){
          driverDocumentList.value = value.documents!;
        } else {
          driverDocumentList.value = []; // or handle empty case
        }
      });
    } catch (e) {
      print('Error in getDocument: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
