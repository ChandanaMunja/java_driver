import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jippydriver_driver/utils/app_logger.dart';

/// Cache entry model with LRU tracking
class CacheEntry {
  final String data;
  final DateTime cachedAt;
  final Duration ttl;
  DateTime lastAccessed; // For LRU eviction
  
  CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.ttl,
  }) : lastAccessed = DateTime.now();
  
  bool get isExpired => DateTime.now().difference(cachedAt) > ttl;
  
  /// Update last accessed time
  void touch() {
    lastAccessed = DateTime.now();
  }
  
  /// Estimate memory size in bytes
  int get estimatedSize => data.length * 2; // Rough estimate (UTF-16)
  
  Map<String, dynamic> toJson() => {
    'data': data,
    'cachedAt': cachedAt.toIso8601String(),
    'ttlSeconds': ttl.inSeconds,
  };
  
  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    data: json['data'] as String,
    cachedAt: DateTime.parse(json['cachedAt'] as String),
    ttl: Duration(seconds: json['ttlSeconds'] as int),
  );
}

/// Cache strategy enum
enum CacheStrategy {
  vendor,      // 1 hour - rarely changes
  order,        // 30 seconds - changes frequently
  driverProfile, // 10 seconds - changes moderately
  settings,     // 24 hours - rarely changes
  custom,       // Custom TTL
}

/// Centralized API Cache Service with memory management
/// Provides in-memory and persistent caching with TTL support, size limits, and automatic cleanup
class ApiCacheService {
  static final ApiCacheService _instance = ApiCacheService._internal();
  factory ApiCacheService() => _instance;
  ApiCacheService._internal() {
    _startPeriodicCleanup();
  }
  
  // In-memory cache (fast access) - LRU ordered
  final Map<String, CacheEntry> _memoryCache = {};
  
  // Request deduplication - track ongoing requests
  final Map<String, Future<Map<String, dynamic>>> _pendingRequests = {};
  
  // Cache size limits to prevent memory issues
  static const int _maxMemoryEntries = 100; // Maximum cache entries
  static const int _maxMemorySizeMB = 10; // Maximum cache size in MB (~10MB)
  static const int _maxMemorySizeBytes = _maxMemorySizeMB * 1024 * 1024;
  
  // Cleanup intervals
  static const Duration _cleanupInterval = Duration(minutes: 2); // Clean expired every 2 minutes
  static const Duration _sizeCheckInterval = Duration(minutes: 5); // Check size every 5 minutes
  
  Timer? _cleanupTimer;
  Timer? _sizeCheckTimer;
  
  // Cache TTL configurations
  static const Map<CacheStrategy, Duration> _cacheTTL = {
    CacheStrategy.vendor: Duration(hours: 1),
    CacheStrategy.order: Duration(seconds: 30),
    CacheStrategy.driverProfile: Duration(seconds: 10),
    CacheStrategy.settings: Duration(hours: 24),
  };
  
  // SharedPreferences key prefix
  static const String _cachePrefix = 'api_cache_';
  
  /// Start periodic cleanup timers
  void _startPeriodicCleanup() {
    // Clean expired entries periodically
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      cleanExpiredMemoryCache();
    });
    
    // Check cache size and cleanup if needed
    _sizeCheckTimer = Timer.periodic(_sizeCheckInterval, (_) {
      _enforceSizeLimits();
    });
    
    AppLogger.log('✅ Cache cleanup timers started (expired: ${_cleanupInterval.inMinutes}min, size: ${_sizeCheckInterval.inMinutes}min)', tag: 'Cache');
  }
  
  /// Stop cleanup timers (for disposal)
  void _stopPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _sizeCheckTimer?.cancel();
    _cleanupTimer = null;
    _sizeCheckTimer = null;
  }
  
  /// Calculate total cache size in bytes
  int _calculateCacheSize() {
    int totalSize = 0;
    for (final entry in _memoryCache.values) {
      totalSize += entry.estimatedSize;
    }
    return totalSize;
  }
  
  /// Enforce cache size limits using LRU eviction
  void _enforceSizeLimits() {
    // Check if we need to evict entries
    final currentSize = _calculateCacheSize();
    final currentEntries = _memoryCache.length;
    
    bool needsCleanup = false;
    
    // Check entry count limit
    if (currentEntries > _maxMemoryEntries) {
      needsCleanup = true;
      AppLogger.log('⚠️ Cache size limit exceeded: $currentEntries entries (max: $_maxMemoryEntries)', tag: 'Cache');
    }
    
    // Check memory size limit
    if (currentSize > _maxMemorySizeBytes) {
      needsCleanup = true;
      AppLogger.log('⚠️ Cache memory limit exceeded: ${(currentSize / 1024 / 1024).toStringAsFixed(2)}MB (max: ${_maxMemorySizeMB}MB)', tag: 'Cache');
    }
    
    if (!needsCleanup) return;
    
    // Sort entries by last accessed time (LRU - least recently used first)
    final sortedEntries = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
    
    // Remove oldest entries until we're under limits
    int removedCount = 0;
    for (final entry in sortedEntries) {
      // Stop if we're under both limits
      if (_memoryCache.length <= _maxMemoryEntries * 0.8 && // Keep at 80% of max
          _calculateCacheSize() <= _maxMemorySizeBytes * 0.8) {
        break;
      }
      
      _memoryCache.remove(entry.key);
      removedCount++;
    }
    
    if (removedCount > 0) {
      AppLogger.log('🧹 LRU eviction: Removed $removedCount entries. New size: ${_memoryCache.length} entries, ${(_calculateCacheSize() / 1024 / 1024).toStringAsFixed(2)}MB', tag: 'Cache');
    }
  }
  
  /// Get cache key from URL and headers
  String _getCacheKey(String url, Map<String, String>? headers) {
    // Include relevant headers in cache key (e.g., If-None-Match, If-Modified-Since)
    final headerKey = headers?.entries
        .where((e) => e.key.toLowerCase() == 'if-none-match' || 
                     e.key.toLowerCase() == 'if-modified-since')
        .map((e) => '${e.key}:${e.value}')
        .join('|') ?? '';
    
    return '${url}_$headerKey';
  }
  
  /// Get cache strategy from URL pattern
  CacheStrategy _getCacheStrategy(String url) {
    if (url.contains('/restaurant/vendors/') || url.contains('/vendors/')) {
      return CacheStrategy.vendor;
    } else if (url.contains('/orders/') || url.contains('/get-current-reject-accept')) {
      return CacheStrategy.order;
    } else if (url.contains('/users/')) {
      return CacheStrategy.driverProfile;
    } else if (url.contains('/settings') || url.contains('/config')) {
      return CacheStrategy.settings;
    }
    return CacheStrategy.custom;
  }
  
  /// Get TTL for cache strategy
  Duration _getTTL(CacheStrategy strategy, {Duration? customTTL}) {
    if (strategy == CacheStrategy.custom && customTTL != null) {
      return customTTL;
    }
    return _cacheTTL[strategy] ?? Duration(minutes: 5);
  }
  
  /// Get from in-memory cache (updates LRU tracking)
  Map<String, dynamic>? _getFromMemory(String cacheKey) {
    final entry = _memoryCache[cacheKey];
    if (entry == null) return null;
    
    if (entry.isExpired) {
      _memoryCache.remove(cacheKey);
      AppLogger.log('Memory cache expired for: $cacheKey', tag: 'Cache');
      return null;
    }
    
    // Update last accessed time (LRU tracking)
    entry.touch();
    
    AppLogger.log('✅ Memory cache HIT: $cacheKey', tag: 'Cache');
    try {
      return jsonDecode(entry.data) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.log('Error parsing cached data: $e', tag: 'Cache');
      _memoryCache.remove(cacheKey);
      return null;
    }
  }
  
  /// Get from persistent cache (SharedPreferences)
  Future<Map<String, dynamic>?> _getFromPersistent(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = prefs.getString('$_cachePrefix$cacheKey');
      
      if (cacheData == null) return null;
      
      final entryJson = jsonDecode(cacheData) as Map<String, dynamic>;
      final entry = CacheEntry.fromJson(entryJson);
      
      if (entry.isExpired) {
        await prefs.remove('$_cachePrefix$cacheKey');
        AppLogger.log('Persistent cache expired for: $cacheKey', tag: 'Cache');
        return null;
      }
      
      AppLogger.log('✅ Persistent cache HIT: $cacheKey', tag: 'Cache');
      return jsonDecode(entry.data) as Map<String, dynamic>;
    } catch (e) {
      AppLogger.log('Error reading persistent cache: $e', tag: 'Cache');
      return null;
    }
  }
  
  /// Save to in-memory cache (with size limit enforcement)
  void _saveToMemory(String cacheKey, String data, Duration ttl) {
    // Check if we need to evict before adding
    final newEntrySize = data.length * 2; // Rough estimate
    if (_memoryCache.length >= _maxMemoryEntries || 
        _calculateCacheSize() + newEntrySize > _maxMemorySizeBytes) {
      _enforceSizeLimits();
    }
    
    _memoryCache[cacheKey] = CacheEntry(
      data: data,
      cachedAt: DateTime.now(),
      ttl: ttl,
    );
    AppLogger.log('💾 Saved to memory cache: $cacheKey (TTL: ${ttl.inSeconds}s, Size: ${_memoryCache.length}/${_maxMemoryEntries} entries)', tag: 'Cache');
  }
  
  /// Save to persistent cache (SharedPreferences)
  Future<void> _saveToPersistent(String cacheKey, String data, Duration ttl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entry = CacheEntry(
        data: data,
        cachedAt: DateTime.now(),
        ttl: ttl,
      );
      await prefs.setString('$_cachePrefix$cacheKey', jsonEncode(entry.toJson()));
      AppLogger.log('💾 Saved to persistent cache: $cacheKey (TTL: ${ttl.inSeconds}s)', tag: 'Cache');
    } catch (e) {
      AppLogger.log('Error saving persistent cache: $e', tag: 'Cache');
    }
  }
  
  /// Get cached data (checks memory first, then persistent)
  Future<Map<String, dynamic>?> getCached(
    String url,
    Map<String, String>? headers, {
    CacheStrategy? strategy,
    Duration? customTTL,
  }) async {
    final cacheKey = _getCacheKey(url, headers);
    final cacheStrategy = strategy ?? _getCacheStrategy(url);
    
    // Check memory cache first (fastest)
    final memoryData = _getFromMemory(cacheKey);
    if (memoryData != null) {
      return memoryData;
    }
    
    // Check persistent cache (slower but still faster than network)
    final persistentData = await _getFromPersistent(cacheKey);
    if (persistentData != null) {
      // Also restore to memory cache for faster access
      final ttl = _getTTL(cacheStrategy, customTTL: customTTL);
      _saveToMemory(cacheKey, jsonEncode(persistentData), ttl);
      return persistentData;
    }
    
    AppLogger.log('❌ Cache MISS: $cacheKey', tag: 'Cache');
    return null;
  }
  
  /// Save data to cache (both memory and persistent)
  Future<void> saveCache(
    String url,
    Map<String, String>? headers,
    String responseBody, {
    CacheStrategy? strategy,
    Duration? customTTL,
    bool saveToPersistent = true,
  }) async {
    final cacheKey = _getCacheKey(url, headers);
    final cacheStrategy = strategy ?? _getCacheStrategy(url);
    final ttl = _getTTL(cacheStrategy, customTTL: customTTL);
    
    // Always save to memory (fast access)
    _saveToMemory(cacheKey, responseBody, ttl);
    
    // Save to persistent cache if requested (for vendor/settings that rarely change)
    if (saveToPersistent && 
        (cacheStrategy == CacheStrategy.vendor || 
         cacheStrategy == CacheStrategy.settings ||
         cacheStrategy == CacheStrategy.custom)) {
      await _saveToPersistent(cacheKey, responseBody, ttl);
    }
  }
  
  /// Invalidate cache for a specific URL pattern
  Future<void> invalidateCache(String urlPattern) async {
    final keysToRemove = <String>[];
    
    // Invalidate memory cache
    for (final key in _memoryCache.keys) {
      if (key.contains(urlPattern)) {
        keysToRemove.add(key);
      }
    }
    keysToRemove.forEach((key) => _memoryCache.remove(key));
    
    // Invalidate persistent cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith(_cachePrefix) && key.contains(urlPattern)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      AppLogger.log('Error invalidating persistent cache: $e', tag: 'Cache');
    }
    
    AppLogger.log('🗑️ Invalidated cache for pattern: $urlPattern (${keysToRemove.length} entries)', tag: 'Cache');
  }
  
  /// Clear all caches
  Future<void> clearAllCache() async {
    _memoryCache.clear();
    _pendingRequests.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      AppLogger.log('Error clearing persistent cache: $e', tag: 'Cache');
    }
    
    AppLogger.log('🗑️ Cleared all caches', tag: 'Cache');
  }
  
  /// Request deduplication - check if request is already in progress
  Future<Map<String, dynamic>>? getPendingRequest(String url, Map<String, String>? headers) {
    final cacheKey = _getCacheKey(url, headers);
    return _pendingRequests[cacheKey];
  }
  
  /// Register a pending request
  void registerPendingRequest(
    String url,
    Map<String, String>? headers,
    Future<Map<String, dynamic>> requestFuture,
  ) {
    final cacheKey = _getCacheKey(url, headers);
    _pendingRequests[cacheKey] = requestFuture;
    
    // Clean up after request completes (success or error)
    requestFuture.then((_) {
      _pendingRequests.remove(cacheKey);
    }).catchError((_) {
      _pendingRequests.remove(cacheKey);
    });
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryEntries': _memoryCache.length,
      'pendingRequests': _pendingRequests.length,
      'memoryCacheKeys': _memoryCache.keys.toList(),
    };
  }
  
  /// Clean expired entries from memory cache
  void cleanExpiredMemoryCache() {
    final keysToRemove = <String>[];
    final now = DateTime.now();
    
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }
    
    keysToRemove.forEach((key) => _memoryCache.remove(key));
    
    if (keysToRemove.isNotEmpty) {
      AppLogger.log('🧹 Cleaned ${keysToRemove.length} expired memory cache entries. Remaining: ${_memoryCache.length}', tag: 'Cache');
    }
    
    // Also clean up old pending requests that might be stuck
    if (_pendingRequests.length > 50) {
      final oldPending = _pendingRequests.length - 50;
      final keys = _pendingRequests.keys.take(oldPending).toList();
      for (final key in keys) {
        _pendingRequests.remove(key);
      }
      AppLogger.log('🧹 Cleaned $oldPending old pending requests', tag: 'Cache');
    }
  }
  
  /// Get detailed cache statistics
  Map<String, dynamic> getDetailedCacheStats() {
    final totalSize = _calculateCacheSize();
    final expiredCount = _memoryCache.values.where((e) => e.isExpired).length;
    
    return {
      'memoryEntries': _memoryCache.length,
      'maxMemoryEntries': _maxMemoryEntries,
      'memorySizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
      'maxMemorySizeMB': _maxMemorySizeMB,
      'expiredEntries': expiredCount,
      'pendingRequests': _pendingRequests.length,
      'usagePercent': ((_memoryCache.length / _maxMemoryEntries) * 100).toStringAsFixed(1),
    };
  }
  
  /// Force cleanup - removes expired entries and enforces size limits
  void forceCleanup() {
    cleanExpiredMemoryCache();
    _enforceSizeLimits();
    AppLogger.log('🧹 Force cleanup completed. Cache stats: ${getDetailedCacheStats()}', tag: 'Cache');
  }
  
  /// Dispose resources
  void dispose() {
    _stopPeriodicCleanup();
    _memoryCache.clear();
    _pendingRequests.clear();
    AppLogger.log('🔄 Cache service disposed', tag: 'Cache');
  }
}
