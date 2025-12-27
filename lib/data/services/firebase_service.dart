import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '/domain/entities/entities.dart';
import '/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

/// خدمة Firebase للتعامل مع Authentication و Firestore
class FirebaseService {
  static final FirebaseService instance = FirebaseService._init();
  
  FirebaseService._init();

  // Firebase instances
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  
  // Google Sign-In instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// تهيئة Firebase
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      if (kDebugMode) {
        debugPrint('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase initialization error: $e');
      }
      rethrow;
    }
  }

  /// الحصول على حالة المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  /// هل المستخدم مسجل الدخول؟
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream لمتابعة تغييرات حالة المصادقة
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// تسجيل الدخول باستخدام Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // بدء عملية تسجيل الدخول
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // المستخدم ألغى العملية
        return null;
      }

      // الحصول على تفاصيل المصادقة
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // إنشاء credential للـ Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // تسجيل الدخول إلى Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      
      // إنشاء أو تحديث وثيقة المستخدم في Firestore
      if (userCredential.user != null) {
        await _createOrUpdateUserDocument(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Google Sign-In error: $e');
      }
      rethrow;
    }
  }

  /// إنشاء أو تحديث وثيقة المستخدم في Firestore
  Future<void> _createOrUpdateUserDocument(User user) async {
    final userDoc = _firestore.collection(AppConstants.collectionUsers).doc(user.uid);
    final docSnapshot = await userDoc.get();

    final now = DateTime.now().toIso8601String();
    
    if (!docSnapshot.exists) {
      // إنشاء وثيقة جديدة
      await userDoc.set({
        'userId': user.uid,
        'username': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': user.phoneNumber,
        'profilePictureUrl': user.photoURL,
        'userType': AppConstants.userTypeAuthenticated,
        'createdAt': now,
        'updatedAt': now,
      });
    } else {
      // تحديث الوثيقة الموجودة
      await userDoc.update({
        'username': user.displayName ?? docSnapshot.data()?['username'],
        'email': user.email ?? docSnapshot.data()?['email'],
        'profilePictureUrl': user.photoURL ?? docSnapshot.data()?['profilePictureUrl'],
        'updatedAt': now,
      });
    }
  }

  /// الحصول على بيانات المستخدم من Firestore
  Future<UserEntity?> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return UserEntity.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get user data error: $e');
      }
      return null;
    }
  }

  /// تحديث بيانات المستخدم
  Future<void> updateUserData(UserEntity user) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.userId)
          .update(user.toFirestore());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update user data error: $e');
      }
      rethrow;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sign out error: $e');
      }
      rethrow;
    }
  }

  // ============ Firestore Operations for Accounts ============

  /// الحصول على حسابات المستخدم
  Future<List<AccountEntity>> getUserAccounts(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionAccounts)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => AccountEntity.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get user accounts error: $e');
      }
      return [];
    }
  }

  /// إنشاء حساب جديد
  Future<String?> createAccount(AccountEntity account) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.collectionAccounts)
          .add(account.toFirestore());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Create account error: $e');
      }
      return null;
    }
  }

  /// تحديث حساب
  Future<bool> updateAccount(AccountEntity account) async {
    try {
      await _firestore
          .collection(AppConstants.collectionAccounts)
          .doc(account.accountId)
          .update(account.toFirestore());
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update account error: $e');
      }
      return false;
    }
  }

  /// حذف حساب
  Future<bool> deleteAccount(String accountId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionAccounts)
          .doc(accountId)
          .delete();
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Delete account error: $e');
      }
      return false;
    }
  }

  // ============ Firestore Operations for Transactions ============

  /// الحصول على عمليات الحساب
  Future<List<TransactionEntity>> getAccountTransactions(String accountId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionTransactions)
          .where('accountId', isEqualTo: accountId)
          .get();

      final transactions = snapshot.docs
          .map((doc) => TransactionEntity.fromFirestore(doc.data(), doc.id))
          .toList();

      // ترتيب في الذاكرة بدلاً من استخدام orderBy
      transactions.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      
      return transactions;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get account transactions error: $e');
      }
      return [];
    }
  }

  /// إنشاء عملية جديدة
  Future<String?> createTransaction(TransactionEntity transaction) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.collectionTransactions)
          .add(transaction.toFirestore());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Create transaction error: $e');
      }
      return null;
    }
  }

  /// تحديث عملية
  Future<bool> updateTransaction(TransactionEntity transaction) async {
    try {
      await _firestore
          .collection(AppConstants.collectionTransactions)
          .doc(transaction.transactionId)
          .update(transaction.toFirestore());
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update transaction error: $e');
      }
      return false;
    }
  }

  // ============ Firestore Operations for Account Requests ============

  /// إنشاء طلب حساب مشترك
  Future<String?> createAccountRequest(AccountRequestEntity request) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.collectionRequests)
          .add(request.toFirestore());
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Create account request error: $e');
      }
      return null;
    }
  }

  /// الحصول على الطلبات الواردة
  Future<List<AccountRequestEntity>> getIncomingRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionRequests)
          .where('toUserId', isEqualTo: userId)
          .where('requestStatus', isEqualTo: AppConstants.requestStatusPending)
          .get();

      final requests = <AccountRequestEntity>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final fromUserId = data['fromUserId'] as String?;
        
        // الحصول على اسم المرسل
        String? fromUserName;
        String? fromUserEmail;
        if (fromUserId != null) {
          try {
            final userDoc = await _firestore
                .collection(AppConstants.collectionUsers)
                .doc(fromUserId)
                .get();
            if (userDoc.exists) {
              fromUserName = userDoc.data()?['username'] as String?;
              fromUserEmail = userDoc.data()?['email'] as String?;
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Error getting user name: $e');
            }
          }
        }
        
        // إنشاء الكيان مع اسم المرسل
        final requestWithName = AccountRequestEntity.fromFirestore({
          ...data,
          'fromUserName': fromUserName,
          'fromUserEmail': fromUserEmail,
        }, doc.id);
        
        requests.add(requestWithName);
      }
      
      return requests;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get incoming requests error: $e');
      }
      return [];
    }
  }

  /// الرد على طلب حساب
  Future<bool> respondToAccountRequest(String requestId, bool accept, String? notes) async {
    try {
      // الحصول على بيانات الطلب أولاً
      final requestDoc = await _firestore
          .collection(AppConstants.collectionRequests)
          .doc(requestId)
          .get();
      
      if (!requestDoc.exists) {
        if (kDebugMode) {
          debugPrint('Request not found: $requestId');
        }
        return false;
      }
      
      final requestData = requestDoc.data()!;
      
      // تحديث حالة الطلب
      await _firestore
          .collection(AppConstants.collectionRequests)
          .doc(requestId)
          .update({
        'requestStatus': accept 
            ? AppConstants.requestStatusAccepted 
            : AppConstants.requestStatusRejected,
        'respondedAt': DateTime.now().toIso8601String(),
        'responseNotes': notes,
      });
      
      // إذا تم قبول الطلب، إنشاء الحساب المشترك
      if (accept) {
        final now = DateTime.now().toIso8601String();
        final fromUserId = requestData['fromUserId'] as String;
        final toUserId = requestData['toUserId'] as String;
        final accountName = requestData['accountName'] as String;
        final accountType = requestData['accountType'] as String;
        
        // إنشاء حساب مشترك للمرسل
        final account1Data = {
          'accountId': '${requestId}_${fromUserId}',
          'userId': fromUserId,
          'accountName': accountName,
          'accountType': accountType,
          'accountCategory': AppConstants.accountCategoryShared,
          'balance': 0.0,
          'currency': AppConstants.defaultCurrency,
          'otherPartyId': toUserId,
          'otherPartyName': await _getUserName(toUserId),
          'accountStatus': AppConstants.accountStatusActive,
          'createdBy': fromUserId,
          'createdAt': now,
          'updatedAt': now,
          'linkedRequestId': requestId,
        };
        
        // إنشاء حساب مشترك للمستقبل
        final account2Data = {
          'accountId': '${requestId}_${toUserId}',
          'userId': toUserId,
          'accountName': accountName,
          'accountType': accountType,
          'accountCategory': AppConstants.accountCategoryShared,
          'balance': 0.0,
          'currency': AppConstants.defaultCurrency,
          'otherPartyId': fromUserId,
          'otherPartyName': await _getUserName(fromUserId),
          'accountStatus': AppConstants.accountStatusActive,
          'createdBy': toUserId,
          'createdAt': now,
          'updatedAt': now,
          'linkedRequestId': requestId,
        };
        
        // حفظ الحسابات في Firestore
        await _firestore
            .collection(AppConstants.collectionAccounts)
            .doc('${requestId}_${fromUserId}')
            .set(account1Data);
            
        await _firestore
            .collection(AppConstants.collectionAccounts)
            .doc('${requestId}_${toUserId}')
            .set(account2Data);
            
        if (kDebugMode) {
          debugPrint('Shared accounts created successfully');
        }
        
        // إرسال إشعار للمرسل
        await _createNotification(
          userId: fromUserId,
          type: AppConstants.notificationTypeAccountRequest,
          title: 'تم قبول طلبك',
          body: 'تم قبول طلب الحساب المشترك "$accountName"',
          relatedRequestId: requestId,
        );
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Respond to account request error: $e');
      }
      return false;
    }
  }
  
  /// الحصول على اسم المستخدم
  Future<String> _getUserName(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(userId)
          .get();
      if (doc.exists) {
        return doc.data()?['username'] as String? ?? 'مستخدم';
      }
      return 'مستخدم';
    } catch (e) {
      return 'مستخدم';
    }
  }
  
  /// إنشاء إشعار
  Future<void> _createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? relatedAccountId,
    String? relatedRequestId,
  }) async {
    try {
      await _firestore.collection(AppConstants.collectionNotifications).add({
        'userId': userId,
        'notificationType': type,
        'title': title,
        'body': body,
        'relatedAccountId': relatedAccountId,
        'relatedRequestId': relatedRequestId,
        'isRead': false,
        'isDeleted': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Create notification error: $e');
      }
    }
  }

  // ============ User Search ============

  /// البحث عن مستخدمين بالبريد الإلكتروني
  Future<List<UserEntity>> searchUsersByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .where('email', isGreaterThanOrEqualTo: email)
          .where('email', isLessThan: '${email}z')
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => UserEntity.fromFirestore(doc.data(), doc.id))
          .where((user) => user.userId != currentUser?.uid)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Search users error: $e');
      }
      return [];
    }
  }

  // ============ Notifications ============

  /// الحصول على إشعارات المستخدم
  Future<List<NotificationEntity>> getUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionNotifications)
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .get();

      final notifications = snapshot.docs
          .map((doc) => NotificationEntity.fromFirestore(doc.data(), doc.id))
          .toList();

      // ترتيب في الذاكرة
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return notifications;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get notifications error: $e');
      }
      return [];
    }
  }

  /// تعليم إشعار كمقروء
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.collectionNotifications)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Mark notification as read error: $e');
      }
      return false;
    }
  }
}
