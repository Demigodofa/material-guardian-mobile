import 'dart:convert';

import 'package:http/http.dart' as http;

const String _defaultBackendBaseUrl = String.fromEnvironment(
  'MG_BACKEND_BASE_URL',
  defaultValue:
      'https://app-platforms-backend-dev-293518443128.us-east4.run.app',
);

class BackendHealthSnapshot {
  const BackendHealthSnapshot({
    required this.status,
    required this.service,
    required this.mode,
  });

  final String status;
  final String service;
  final String mode;

  factory BackendHealthSnapshot.fromJson(Map<String, dynamic> json) {
    return BackendHealthSnapshot(
      status: json['status'] as String? ?? 'unknown',
      service: json['service'] as String? ?? '',
      mode: json['mode'] as String? ?? 'unknown',
    );
  }
}

class BackendUserSummary {
  const BackendUserSummary({
    required this.id,
    required this.email,
    required this.displayName,
    required this.status,
    required this.createdAt,
    required this.lastLoginAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String status;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  factory BackendUserSummary.fromJson(Map<String, dynamic> json) {
    return BackendUserSummary(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      lastLoginAt: _parseDateTime(json['lastLoginAt']),
    );
  }
}

class BackendMembershipSummary {
  const BackendMembershipSummary({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.role,
    required this.seatStatus,
    required this.invitedAt,
    required this.acceptedAt,
  });

  final String id;
  final String organizationId;
  final String organizationName;
  final String role;
  final String seatStatus;
  final DateTime? invitedAt;
  final DateTime? acceptedAt;

  bool get isAdmin => role == 'owner' || role == 'admin';
  bool get isAccepted => acceptedAt != null;

  factory BackendMembershipSummary.fromJson(Map<String, dynamic> json) {
    return BackendMembershipSummary(
      id: json['id'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      seatStatus: json['seatStatus'] as String? ?? '',
      invitedAt: _parseDateTime(json['invitedAt']),
      acceptedAt: _parseDateTime(json['acceptedAt']),
    );
  }
}

class BackendTrialState {
  const BackendTrialState({
    required this.productCode,
    required this.jobsAllowed,
    required this.jobsUsed,
    required this.jobsRemaining,
    required this.status,
  });

  final String productCode;
  final int jobsAllowed;
  final int jobsUsed;
  final int jobsRemaining;
  final String status;

  factory BackendTrialState.fromJson(Map<String, dynamic> json) {
    return BackendTrialState(
      productCode: json['productCode'] as String? ?? '',
      jobsAllowed: (json['jobsAllowed'] as num?)?.toInt() ?? 0,
      jobsUsed: (json['jobsUsed'] as num?)?.toInt() ?? 0,
      jobsRemaining: (json['jobsRemaining'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
    );
  }
}

class BackendEntitlementSnapshot {
  const BackendEntitlementSnapshot({
    required this.productCode,
    required this.planCode,
    required this.accessState,
    required this.seatAvailability,
    required this.subscriptionState,
    required this.trialRemaining,
    required this.organizationId,
    required this.startsAt,
    required this.endsAt,
  });

  final String productCode;
  final String? planCode;
  final String accessState;
  final String seatAvailability;
  final String subscriptionState;
  final int trialRemaining;
  final String? organizationId;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory BackendEntitlementSnapshot.fromJson(Map<String, dynamic> json) {
    return BackendEntitlementSnapshot(
      productCode: json['productCode'] as String? ?? '',
      planCode: json['planCode'] as String?,
      accessState: json['accessState'] as String? ?? 'locked',
      seatAvailability: json['seatAvailability'] as String? ?? 'not_applicable',
      subscriptionState: json['subscriptionState'] as String? ?? 'inactive',
      trialRemaining: (json['trialRemaining'] as num?)?.toInt() ?? 0,
      organizationId: json['organizationId'] as String?,
      startsAt: _parseDateTime(json['startsAt']),
      endsAt: _parseDateTime(json['endsAt']),
    );
  }
}

class BackendSessionSnapshot {
  const BackendSessionSnapshot({
    required this.id,
    required this.deviceLabel,
    required this.platform,
    required this.status,
    required this.issuedAt,
    required this.lastSeenAt,
    required this.revokedAt,
  });

  final String id;
  final String deviceLabel;
  final String platform;
  final String status;
  final DateTime? issuedAt;
  final DateTime? lastSeenAt;
  final DateTime? revokedAt;

  factory BackendSessionSnapshot.fromJson(Map<String, dynamic> json) {
    return BackendSessionSnapshot(
      id: json['id'] as String? ?? '',
      deviceLabel: json['deviceLabel'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      status: json['status'] as String? ?? '',
      issuedAt: _parseDateTime(json['issuedAt']),
      lastSeenAt: _parseDateTime(json['lastSeenAt']),
      revokedAt: _parseDateTime(json['revokedAt']),
    );
  }
}

class BackendMeSnapshot {
  const BackendMeSnapshot({
    required this.user,
    required this.memberships,
    required this.currentSeatOrganizationId,
    required this.currentSeatStatus,
    required this.trialState,
    required this.activeEntitlement,
    required this.activeSession,
  });

  final BackendUserSummary user;
  final List<BackendMembershipSummary> memberships;
  final String? currentSeatOrganizationId;
  final String currentSeatStatus;
  final BackendTrialState? trialState;
  final BackendEntitlementSnapshot activeEntitlement;
  final BackendSessionSnapshot? activeSession;

  factory BackendMeSnapshot.fromJson(Map<String, dynamic> json) {
    final currentSeatAssignment =
        json['currentSeatAssignment'] as Map<String, dynamic>? ?? const {};
    return BackendMeSnapshot(
      user: BackendUserSummary.fromJson(
        json['user'] as Map<String, dynamic>? ?? const {},
      ),
      memberships: ((json['memberships'] as List<dynamic>?) ?? const [])
          .map(
            (item) =>
                BackendMembershipSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      currentSeatOrganizationId:
          currentSeatAssignment['organizationId'] as String?,
      currentSeatStatus:
          currentSeatAssignment['status'] as String? ?? 'not_applicable',
      trialState: json['trialState'] is Map<String, dynamic>
          ? BackendTrialState.fromJson(
              json['trialState'] as Map<String, dynamic>,
            )
          : null,
      activeEntitlement: BackendEntitlementSnapshot.fromJson(
        json['activeEntitlement'] as Map<String, dynamic>? ?? const {},
      ),
      activeSession: json['activeSession'] is Map<String, dynamic>
          ? BackendSessionSnapshot.fromJson(
              json['activeSession'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class BackendOrganizationMemberSnapshot {
  const BackendOrganizationMemberSnapshot({
    required this.membershipId,
    required this.userId,
    required this.name,
    required this.email,
    required this.userStatus,
    required this.role,
    required this.seatStatus,
    required this.seatAssigned,
    required this.invitedAt,
    required this.acceptedAt,
    required this.lastActive,
    required this.activeDeviceSummary,
  });

  final String membershipId;
  final String userId;
  final String name;
  final String email;
  final String userStatus;
  final String role;
  final String seatStatus;
  final bool seatAssigned;
  final DateTime? invitedAt;
  final DateTime? acceptedAt;
  final DateTime? lastActive;
  final String? activeDeviceSummary;

  factory BackendOrganizationMemberSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    return BackendOrganizationMemberSnapshot(
      membershipId: json['membershipId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      userStatus: json['userStatus'] as String? ?? '',
      role: json['role'] as String? ?? '',
      seatStatus: json['seatStatus'] as String? ?? '',
      seatAssigned: json['seatAssigned'] as bool? ?? false,
      invitedAt: _parseDateTime(json['invitedAt']),
      acceptedAt: _parseDateTime(json['acceptedAt']),
      lastActive: _parseDateTime(json['lastActive']),
      activeDeviceSummary: json['activeDeviceSummary'] as String?,
    );
  }
}

class BackendOrganizationSummary {
  const BackendOrganizationSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.planCode,
    required this.seatLimit,
    required this.seatsAssigned,
    required this.seatsRemaining,
    required this.userCount,
    required this.members,
  });

  final String id;
  final String name;
  final String status;
  final String? planCode;
  final int seatLimit;
  final int seatsAssigned;
  final int seatsRemaining;
  final int userCount;
  final List<BackendOrganizationMemberSnapshot> members;

  factory BackendOrganizationSummary.fromJson(Map<String, dynamic> json) {
    return BackendOrganizationSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      planCode: json['planCode'] as String?,
      seatLimit: (json['seatLimit'] as num?)?.toInt() ?? 0,
      seatsAssigned: (json['seatsAssigned'] as num?)?.toInt() ?? 0,
      seatsRemaining: (json['seatsRemaining'] as num?)?.toInt() ?? 0,
      userCount: (json['userCount'] as num?)?.toInt() ?? 0,
      members: ((json['members'] as List<dynamic>?) ?? const [])
          .map(
            (item) => BackendOrganizationMemberSnapshot.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(growable: false),
    );
  }
}

class BackendOrganizationAccessGrantSnapshot {
  const BackendOrganizationAccessGrantSnapshot({
    required this.id,
    required this.membershipId,
    required this.organizationId,
    required this.email,
    required this.validationMode,
    required this.status,
    required this.expiresAt,
    required this.demoAccessCode,
    required this.createdAt,
  });

  final String id;
  final String membershipId;
  final String organizationId;
  final String email;
  final String validationMode;
  final String status;
  final DateTime? expiresAt;
  final String? demoAccessCode;
  final DateTime? createdAt;

  factory BackendOrganizationAccessGrantSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    return BackendOrganizationAccessGrantSnapshot(
      id: json['id'] as String? ?? '',
      membershipId: json['membershipId'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      validationMode: json['validationMode'] as String? ?? '',
      status: json['status'] as String? ?? '',
      expiresAt: _parseDateTime(json['expiresAt']),
      demoAccessCode: json['demoAccessCode'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

class BackendPlanAdminPolicySnapshot {
  const BackendPlanAdminPolicySnapshot({
    required this.requiresOrgAdmin,
    required this.includedAdminLimit,
    required this.includedAdminLimitIsPlaceholder,
    required this.launchValidationModes,
    required this.placeholderValidationModes,
  });

  final bool requiresOrgAdmin;
  final int? includedAdminLimit;
  final bool includedAdminLimitIsPlaceholder;
  final List<String> launchValidationModes;
  final List<String> placeholderValidationModes;

  factory BackendPlanAdminPolicySnapshot.fromJson(Map<String, dynamic> json) {
    return BackendPlanAdminPolicySnapshot(
      requiresOrgAdmin: json['requiresOrgAdmin'] as bool? ?? false,
      includedAdminLimit: (json['includedAdminLimit'] as num?)?.toInt(),
      includedAdminLimitIsPlaceholder:
          json['includedAdminLimitIsPlaceholder'] as bool? ?? false,
      launchValidationModes:
          ((json['launchValidationModes'] as List<dynamic>?) ?? const [])
              .map((item) => item.toString())
              .toList(growable: false),
      placeholderValidationModes:
          ((json['placeholderValidationModes'] as List<dynamic>?) ?? const [])
              .map((item) => item.toString())
              .toList(growable: false),
    );
  }
}

class BackendFutureBillingSnapshot {
  const BackendFutureBillingSnapshot({
    required this.placeholdersOnly,
    required this.proTierPlaceholder,
    required this.meteredUsagePlaceholder,
    required this.overageWalletPlaceholder,
  });

  final bool placeholdersOnly;
  final bool proTierPlaceholder;
  final bool meteredUsagePlaceholder;
  final bool overageWalletPlaceholder;

  factory BackendFutureBillingSnapshot.fromJson(Map<String, dynamic> json) {
    return BackendFutureBillingSnapshot(
      placeholdersOnly: json['placeholdersOnly'] as bool? ?? true,
      proTierPlaceholder: json['proTierPlaceholder'] as bool? ?? true,
      meteredUsagePlaceholder: json['meteredUsagePlaceholder'] as bool? ?? true,
      overageWalletPlaceholder:
          json['overageWalletPlaceholder'] as bool? ?? true,
    );
  }
}

class BackendPlanSnapshot {
  const BackendPlanSnapshot({
    required this.planCode,
    required this.productCode,
    required this.audienceType,
    required this.billingInterval,
    required this.seatLimit,
    required this.displayPrice,
    required this.displayPriceCents,
    required this.annualSavingsDisplay,
    required this.annualSavingsCents,
    required this.savingsCopy,
    required this.appleStoreProductId,
    required this.googleStoreProductId,
    required this.adminPolicy,
    required this.futureBilling,
  });

  final String planCode;
  final String productCode;
  final String audienceType;
  final String billingInterval;
  final int seatLimit;
  final String displayPrice;
  final int displayPriceCents;
  final String? annualSavingsDisplay;
  final int? annualSavingsCents;
  final String? savingsCopy;
  final String? appleStoreProductId;
  final String? googleStoreProductId;
  final BackendPlanAdminPolicySnapshot? adminPolicy;
  final BackendFutureBillingSnapshot futureBilling;

  bool get isBusiness => audienceType == 'business';
  bool get isIndividual => audienceType == 'individual';

  String? storeProductIdForPlatform(String platform) {
    switch (platform) {
      case 'android':
        return googleStoreProductId;
      case 'ios':
        return appleStoreProductId;
      default:
        return null;
    }
  }

  factory BackendPlanSnapshot.fromJson(Map<String, dynamic> json) {
    final storeProductIds =
        json['storeProductIds'] as Map<String, dynamic>? ?? const {};
    return BackendPlanSnapshot(
      planCode: json['planCode'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      audienceType: json['audienceType'] as String? ?? '',
      billingInterval: json['billingInterval'] as String? ?? '',
      seatLimit: (json['seatLimit'] as num?)?.toInt() ?? 0,
      displayPrice: json['displayPrice'] as String? ?? '',
      displayPriceCents: (json['displayPriceCents'] as num?)?.toInt() ?? 0,
      annualSavingsDisplay: json['annualSavingsDisplay'] as String?,
      annualSavingsCents: (json['annualSavingsCents'] as num?)?.toInt(),
      savingsCopy: json['savingsCopy'] as String?,
      appleStoreProductId: storeProductIds['apple'] as String?,
      googleStoreProductId: storeProductIds['google'] as String?,
      adminPolicy: json['adminPolicy'] is Map<String, dynamic>
          ? BackendPlanAdminPolicySnapshot.fromJson(
              json['adminPolicy'] as Map<String, dynamic>,
            )
          : null,
      futureBilling: BackendFutureBillingSnapshot.fromJson(
        json['futureBilling'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class BackendInviteOrganizationMemberResult {
  const BackendInviteOrganizationMemberResult({
    required this.organization,
    required this.member,
    required this.accessGrant,
  });

  final BackendOrganizationSummary organization;
  final BackendOrganizationMemberSnapshot member;
  final BackendOrganizationAccessGrantSnapshot accessGrant;

  factory BackendInviteOrganizationMemberResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return BackendInviteOrganizationMemberResult(
      organization: BackendOrganizationSummary.fromJson(
        json['organization'] as Map<String, dynamic>? ?? const {},
      ),
      member: BackendOrganizationMemberSnapshot.fromJson(
        json['member'] as Map<String, dynamic>? ?? const {},
      ),
      accessGrant: BackendOrganizationAccessGrantSnapshot.fromJson(
        json['accessGrant'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class BackendCreateOrganizationResult {
  const BackendCreateOrganizationResult({
    required this.organization,
    required this.ownerMember,
  });

  final BackendOrganizationSummary organization;
  final BackendOrganizationMemberSnapshot ownerMember;

  factory BackendCreateOrganizationResult.fromJson(Map<String, dynamic> json) {
    return BackendCreateOrganizationResult(
      organization: BackendOrganizationSummary.fromJson(
        json['organization'] as Map<String, dynamic>? ?? const {},
      ),
      ownerMember: BackendOrganizationMemberSnapshot.fromJson(
        json['ownerMember'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class BackendUpdateOrganizationMemberSeatResult {
  const BackendUpdateOrganizationMemberSeatResult({
    required this.organization,
    required this.member,
  });

  final BackendOrganizationSummary organization;
  final BackendOrganizationMemberSnapshot member;

  factory BackendUpdateOrganizationMemberSeatResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return BackendUpdateOrganizationMemberSeatResult(
      organization: BackendOrganizationSummary.fromJson(
        json['organization'] as Map<String, dynamic>? ?? const {},
      ),
      member: BackendOrganizationMemberSnapshot.fromJson(
        json['member'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class BackendRemoveOrganizationMemberResult {
  const BackendRemoveOrganizationMemberResult({
    required this.organization,
    required this.removedMembershipId,
    required this.removedUserId,
    required this.releasedSeat,
  });

  final BackendOrganizationSummary organization;
  final String removedMembershipId;
  final String removedUserId;
  final bool releasedSeat;

  factory BackendRemoveOrganizationMemberResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return BackendRemoveOrganizationMemberResult(
      organization: BackendOrganizationSummary.fromJson(
        json['organization'] as Map<String, dynamic>? ?? const {},
      ),
      removedMembershipId: json['removedMembershipId'] as String? ?? '',
      removedUserId: json['removedUserId'] as String? ?? '',
      releasedSeat: json['releasedSeat'] as bool? ?? false,
    );
  }
}

class BackendRedeemOrganizationAccessResult {
  const BackendRedeemOrganizationAccessResult({
    required this.organization,
    required this.member,
    required this.activeEntitlement,
  });

  final BackendOrganizationSummary organization;
  final BackendOrganizationMemberSnapshot member;
  final BackendEntitlementSnapshot activeEntitlement;

  factory BackendRedeemOrganizationAccessResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return BackendRedeemOrganizationAccessResult(
      organization: BackendOrganizationSummary.fromJson(
        json['organization'] as Map<String, dynamic>? ?? const {},
      ),
      member: BackendOrganizationMemberSnapshot.fromJson(
        json['member'] as Map<String, dynamic>? ?? const {},
      ),
      activeEntitlement: BackendEntitlementSnapshot.fromJson(
        json['activeEntitlement'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class BackendAuthStartSnapshot {
  const BackendAuthStartSnapshot({
    required this.flowId,
    required this.deliveryTarget,
    required this.expiresAt,
    required this.demoCode,
  });

  final String flowId;
  final String deliveryTarget;
  final DateTime? expiresAt;
  final String demoCode;

  factory BackendAuthStartSnapshot.fromJson(Map<String, dynamic> json) {
    return BackendAuthStartSnapshot(
      flowId: json['flowId'] as String? ?? '',
      deliveryTarget: json['deliveryTarget'] as String? ?? '',
      expiresAt: _parseDateTime(json['expiresAt']),
      demoCode: json['demoCode'] as String? ?? '',
    );
  }
}

class BackendSessionConflictSnapshot {
  const BackendSessionConflictSnapshot({
    required this.activeSessionId,
    required this.activeDeviceLabel,
    required this.activePlatform,
    required this.lastSeenAt,
  });

  final String activeSessionId;
  final String activeDeviceLabel;
  final String activePlatform;
  final DateTime? lastSeenAt;

  factory BackendSessionConflictSnapshot.fromJson(Map<String, dynamic> json) {
    return BackendSessionConflictSnapshot(
      activeSessionId: json['activeSessionId'] as String? ?? '',
      activeDeviceLabel: json['activeDeviceLabel'] as String? ?? '',
      activePlatform: json['activePlatform'] as String? ?? '',
      lastSeenAt: _parseDateTime(json['lastSeenAt']),
    );
  }
}

class BackendAuthResult {
  const BackendAuthResult({
    required this.status,
    required this.user,
    required this.memberships,
    required this.activeEntitlement,
    required this.session,
    required this.accessToken,
    required this.refreshToken,
    required this.pendingSessionId,
    required this.conflict,
  });

  final String status;
  final BackendUserSummary? user;
  final List<BackendMembershipSummary> memberships;
  final BackendEntitlementSnapshot? activeEntitlement;
  final BackendSessionSnapshot? session;
  final String? accessToken;
  final String? refreshToken;
  final String? pendingSessionId;
  final BackendSessionConflictSnapshot? conflict;

  bool get isAuthenticated => status == 'authenticated';
  bool get requiresSessionReplacement =>
      status == 'session_replacement_required';

  factory BackendAuthResult.fromJson(Map<String, dynamic> json) {
    return BackendAuthResult(
      status: json['status'] as String? ?? '',
      user: json['user'] is Map<String, dynamic>
          ? BackendUserSummary.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      memberships: ((json['memberships'] as List<dynamic>?) ?? const [])
          .map(
            (item) =>
                BackendMembershipSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      activeEntitlement: json['activeEntitlement'] is Map<String, dynamic>
          ? BackendEntitlementSnapshot.fromJson(
              json['activeEntitlement'] as Map<String, dynamic>,
            )
          : null,
      session: json['session'] is Map<String, dynamic>
          ? BackendSessionSnapshot.fromJson(
              json['session'] as Map<String, dynamic>,
            )
          : null,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      pendingSessionId: json['pendingSessionId'] as String?,
      conflict: json['conflict'] is Map<String, dynamic>
          ? BackendSessionConflictSnapshot.fromJson(
              json['conflict'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class BackendLogoutResult {
  const BackendLogoutResult({
    required this.revokedSessionId,
    required this.revokedAt,
  });

  final String revokedSessionId;
  final DateTime? revokedAt;

  factory BackendLogoutResult.fromJson(Map<String, dynamic> json) {
    return BackendLogoutResult(
      revokedSessionId: json['revokedSessionId'] as String? ?? '',
      revokedAt: _parseDateTime(json['revokedAt']),
    );
  }
}

class BackendDeleteAccountResult {
  const BackendDeleteAccountResult({
    required this.deletedUserId,
    required this.deletedAt,
    required this.storeSubscriptionActionRequired,
    required this.storeSubscriptionActionMessage,
  });

  final String deletedUserId;
  final DateTime? deletedAt;
  final bool storeSubscriptionActionRequired;
  final String? storeSubscriptionActionMessage;

  factory BackendDeleteAccountResult.fromJson(Map<String, dynamic> json) {
    return BackendDeleteAccountResult(
      deletedUserId: json['deletedUserId'] as String? ?? '',
      deletedAt: _parseDateTime(json['deletedAt']),
      storeSubscriptionActionRequired:
          json['storeSubscriptionActionRequired'] as bool? ?? false,
      storeSubscriptionActionMessage:
          json['storeSubscriptionActionMessage'] as String?,
    );
  }
}

class BackendPurchaseVerificationResult {
  const BackendPurchaseVerificationResult({
    required this.provider,
    required this.purchaseEventId,
    required this.subscriptionId,
    required this.entitlementId,
    required this.planCode,
    required this.productCode,
    required this.targetType,
    required this.organizationId,
    required this.activeEntitlement,
  });

  final String provider;
  final String purchaseEventId;
  final String subscriptionId;
  final String entitlementId;
  final String planCode;
  final String productCode;
  final String targetType;
  final String? organizationId;
  final BackendEntitlementSnapshot activeEntitlement;

  factory BackendPurchaseVerificationResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return BackendPurchaseVerificationResult(
      provider: json['provider'] as String? ?? '',
      purchaseEventId: json['purchaseEventId'] as String? ?? '',
      subscriptionId: json['subscriptionId'] as String? ?? '',
      entitlementId: json['entitlementId'] as String? ?? '',
      planCode: json['planCode'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      organizationId: json['organizationId'] as String?,
      activeEntitlement: BackendEntitlementSnapshot.fromJson(
        json['activeEntitlement'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class BackendApiService {
  BackendApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUri = _normalizedBaseUri(baseUrl ?? _defaultBackendBaseUrl);

  final http.Client _client;
  final Uri _baseUri;

  String get baseUrl => _baseUri.toString().replaceFirst(RegExp(r'/$'), '');

  Future<BackendHealthSnapshot> fetchHealth() async {
    final response = await _client.get(_buildUri('health'));
    return BackendHealthSnapshot.fromJson(
      _decodeJsonObject(response, endpoint: '/health'),
    );
  }

  Future<List<BackendPlanSnapshot>> fetchPlans() async {
    final response = await _client.get(_buildUri('plans'));
    final payload = _decodeJsonObject(response, endpoint: '/plans');
    final plans = payload['plans'];
    if (plans is! List<dynamic>) {
      throw BackendApiException(
        'Backend response for /plans did not include a plan list.',
      );
    }
    return plans
        .map(
          (item) => BackendPlanSnapshot.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  Future<BackendAuthStartSnapshot> startAuth({
    required String email,
    String? displayName,
  }) async {
    final response = await _client.post(
      _buildUri('auth/start'),
      headers: _jsonHeaders,
      body: jsonEncode({'email': email, 'displayName': displayName}),
    );
    return BackendAuthStartSnapshot.fromJson(
      _decodeJsonObject(response, endpoint: '/auth/start'),
    );
  }

  Future<BackendAuthResult> completeAuth({
    required String flowId,
    required String email,
    required String code,
    required String deviceLabel,
    required String platform,
  }) async {
    final response = await _client.post(
      _buildUri('auth/complete'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'flowId': flowId,
        'email': email,
        'code': code,
        'deviceLabel': deviceLabel,
        'platform': platform,
      }),
    );
    return BackendAuthResult.fromJson(
      _decodeJsonObject(response, endpoint: '/auth/complete'),
    );
  }

  Future<BackendAuthResult> replaceSession({
    required String pendingSessionId,
  }) async {
    final response = await _client.post(
      _buildUri('sessions/replace'),
      headers: _jsonHeaders,
      body: jsonEncode({'pendingSessionId': pendingSessionId}),
    );
    return BackendAuthResult.fromJson(
      _decodeJsonObject(response, endpoint: '/sessions/replace'),
    );
  }

  Future<BackendAuthResult> refreshSession({
    required String refreshToken,
  }) async {
    final response = await _client.post(
      _buildUri('auth/refresh'),
      headers: _jsonHeaders,
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    return BackendAuthResult.fromJson(
      _decodeJsonObject(response, endpoint: '/auth/refresh'),
    );
  }

  Future<BackendLogoutResult> logout({required String accessToken}) async {
    final response = await _client.post(
      _buildUri('auth/logout'),
      headers: _authorizedJsonHeaders(accessToken),
      body: jsonEncode(const {}),
    );
    return BackendLogoutResult.fromJson(
      _decodeJsonObject(response, endpoint: '/auth/logout'),
    );
  }

  Future<BackendMeSnapshot> fetchMe({required String accessToken}) async {
    final response = await _client.get(
      _buildUri('me'),
      headers: _authorizedHeaders(accessToken),
    );
    return BackendMeSnapshot.fromJson(
      _decodeJsonObject(response, endpoint: '/me'),
    );
  }

  Future<BackendDeleteAccountResult> deleteAccount({
    required String accessToken,
  }) async {
    final response = await _client.delete(
      _buildUri('me'),
      headers: _authorizedHeaders(accessToken),
    );
    return BackendDeleteAccountResult.fromJson(
      _decodeJsonObject(response, endpoint: '/me'),
    );
  }

  Future<BackendEntitlementSnapshot> fetchCurrentEntitlement({
    required String accessToken,
  }) async {
    final response = await _client.get(
      _buildUri('entitlements/current'),
      headers: _authorizedHeaders(accessToken),
    );
    return BackendEntitlementSnapshot.fromJson(
      _decodeJsonObject(response, endpoint: '/entitlements/current'),
    );
  }

  Future<BackendCreateOrganizationResult> createOrganization({
    required String name,
    required String accessToken,
  }) async {
    final response = await _client.post(
      _buildUri('organizations'),
      headers: _authorizedJsonHeaders(accessToken),
      body: jsonEncode({'name': name}),
    );
    return BackendCreateOrganizationResult.fromJson(
      _decodeJsonObject(response, endpoint: '/organizations'),
    );
  }

  Future<BackendOrganizationSummary> fetchOrganizationSummary({
    required String organizationId,
    required String accessToken,
  }) async {
    final response = await _client.get(
      _buildUri('organizations/$organizationId'),
      headers: _authorizedHeaders(accessToken),
    );
    return BackendOrganizationSummary.fromJson(
      _decodeJsonObject(response, endpoint: '/organizations/$organizationId'),
    );
  }

  Future<BackendRedeemOrganizationAccessResult> redeemOrganizationAccess({
    required String organizationId,
    required String code,
    required String accessToken,
  }) async {
    final response = await _client.post(
      _buildUri('organizations/access-grants/redeem'),
      headers: _authorizedJsonHeaders(accessToken),
      body: jsonEncode({'organizationId': organizationId, 'code': code}),
    );
    return BackendRedeemOrganizationAccessResult.fromJson(
      _decodeJsonObject(
        response,
        endpoint: '/organizations/access-grants/redeem',
      ),
    );
  }

  Future<BackendInviteOrganizationMemberResult> inviteOrganizationMember({
    required String organizationId,
    required String accessToken,
    required String email,
    String? displayName,
    String role = 'member',
  }) async {
    final response = await _client.post(
      _buildUri('organizations/$organizationId/members/invite'),
      headers: _authorizedJsonHeaders(accessToken),
      body: jsonEncode({
        'email': email,
        'displayName': displayName,
        'role': role,
      }),
    );
    return BackendInviteOrganizationMemberResult.fromJson(
      _decodeJsonObject(
        response,
        endpoint: '/organizations/$organizationId/members/invite',
      ),
    );
  }

  Future<BackendInviteOrganizationMemberResult> resendOrganizationMemberAccess({
    required String organizationId,
    required String membershipId,
    required String accessToken,
  }) async {
    final response = await _client.post(
      _buildUri(
        'organizations/$organizationId/members/$membershipId/resend-access',
      ),
      headers: _authorizedHeaders(accessToken),
    );
    return BackendInviteOrganizationMemberResult.fromJson(
      _decodeJsonObject(
        response,
        endpoint:
            '/organizations/$organizationId/members/$membershipId/resend-access',
      ),
    );
  }

  Future<BackendUpdateOrganizationMemberSeatResult>
  updateOrganizationMemberSeat({
    required String organizationId,
    required String membershipId,
    required String accessToken,
    required bool assignSeat,
  }) async {
    final response = await _client.post(
      _buildUri('organizations/$organizationId/members/$membershipId/seat'),
      headers: _authorizedJsonHeaders(accessToken),
      body: jsonEncode({'assignSeat': assignSeat}),
    );
    return BackendUpdateOrganizationMemberSeatResult.fromJson(
      _decodeJsonObject(
        response,
        endpoint: '/organizations/$organizationId/members/$membershipId/seat',
      ),
    );
  }

  Future<BackendRemoveOrganizationMemberResult> removeOrganizationMember({
    required String organizationId,
    required String membershipId,
    required String accessToken,
  }) async {
    final response = await _client.delete(
      _buildUri('organizations/$organizationId/members/$membershipId'),
      headers: _authorizedHeaders(accessToken),
    );
    return BackendRemoveOrganizationMemberResult.fromJson(
      _decodeJsonObject(
        response,
        endpoint: '/organizations/$organizationId/members/$membershipId',
      ),
    );
  }

  Future<BackendPurchaseVerificationResult> verifyPurchase({
    required String provider,
    required String accessToken,
    required String planCode,
    required String providerTransactionRef,
    String? organizationId,
    String? providerOriginalRef,
    String? rawStatus,
    String? googlePackageName,
    String? googleProductId,
    String? googlePurchaseToken,
  }) async {
    final response = await _client.post(
      _buildUri('purchases/$provider/verify'),
      headers: _authorizedJsonHeaders(accessToken),
      body: jsonEncode({
        'planCode': planCode,
        'organizationId': organizationId,
        'providerTransactionRef': providerTransactionRef,
        'providerOriginalRef': providerOriginalRef,
        'rawStatus': rawStatus,
        'googlePackageName': googlePackageName,
        'googleProductId': googleProductId,
        'googlePurchaseToken': googlePurchaseToken,
      }),
    );
    return BackendPurchaseVerificationResult.fromJson(
      _decodeJsonObject(response, endpoint: '/purchases/$provider/verify'),
    );
  }

  Uri _buildUri(String path) {
    return _baseUri.resolve(path);
  }

  Map<String, String> _authorizedHeaders(String accessToken) {
    return <String, String>{'Authorization': 'Bearer $accessToken'};
  }

  Map<String, String> _authorizedJsonHeaders(String accessToken) {
    return <String, String>{
      ..._authorizedHeaders(accessToken),
      ..._jsonHeaders,
    };
  }

  Map<String, dynamic> _decodeJsonObject(
    http.Response response, {
    required String endpoint,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        'Backend request to $endpoint failed with '
        '${response.statusCode}: ${response.body}',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw BackendApiException(
        'Backend response for $endpoint was not a JSON object.',
      );
    }
    return decoded;
  }

  static Uri _normalizedBaseUri(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      throw BackendApiException('Backend base URL cannot be empty.');
    }
    final normalized = trimmed.endsWith('/') ? trimmed : '$trimmed/';
    return Uri.parse(normalized);
  }
}

class BackendApiException implements Exception {
  const BackendApiException(this.message, {this.statusCode, this.responseBody});

  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() => message;
}

DateTime? _parseDateTime(Object? rawValue) {
  if (rawValue is! String || rawValue.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(rawValue);
}

const Map<String, String> _jsonHeaders = <String, String>{
  'Content-Type': 'application/json',
};
