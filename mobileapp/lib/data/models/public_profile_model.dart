// lib/data/models/public_profile_model.dart
// Model pentru profilurile publice ale utilizatorilor

/// Model pentru profilul public al unui utilizator
class PublicProfileModel {
  final int id;
  final String name;
  final String? avatar;
  final DateTime? memberSince;
  final ProfileStats stats;

  PublicProfileModel({
    required this.id,
    required this.name,
    this.avatar,
    this.memberSince,
    required this.stats,
  });

  factory PublicProfileModel.fromJson(Map<String, dynamic> json) {
    return PublicProfileModel(
      id: json['id'],
      name: json['name'] ?? 'Anonymous User',
      avatar: json['avatar'],
      memberSince: json['memberSince'] != null
          ? DateTime.parse(json['memberSince'])
          : null,
      stats: ProfileStats.fromJson(json['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'memberSince': memberSince?.toIso8601String(),
      'stats': stats.toJson(),
    };
  }
}

/// Statistici pentru profil
class ProfileStats {
  final int totalPets;
  final int availablePets;
  final int adoptedPets;

  ProfileStats({
    this.totalPets = 0,
    this.availablePets = 0,
    this.adoptedPets = 0,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      totalPets: json['totalPets'] ?? 0,
      availablePets: json['availablePets'] ?? 0,
      adoptedPets: json['adoptedPets'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPets': totalPets,
      'availablePets': availablePets,
      'adoptedPets': adoptedPets,
    };
  }
}

/// Model pentru rezultatele căutării de utilizatori
class UserSearchResult {
  final int id;
  final String name;
  final String? avatar;
  final DateTime? memberSince;
  final int availablePets;

  UserSearchResult({
    required this.id,
    required this.name,
    this.avatar,
    this.memberSince,
    this.availablePets = 0,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      name: json['name'] ?? 'Anonymous User',
      avatar: json['avatar'],
      memberSince: json['memberSince'] != null
          ? DateTime.parse(json['memberSince'])
          : null,
      availablePets: json['availablePets'] ?? 0,
    );
  }
}

/// Model pentru statisticile owner-ului (pentru dashboard)
class OwnerStats {
  final int totalPets;
  final int availablePets;
  final int adoptedPets;
  final int pendingRequests;
  final int totalRequests;

  OwnerStats({
    this.totalPets = 0,
    this.availablePets = 0,
    this.adoptedPets = 0,
    this.pendingRequests = 0,
    this.totalRequests = 0,
  });

  factory OwnerStats.fromJson(Map<String, dynamic> json) {
    return OwnerStats(
      totalPets: json['totalPets'] ?? 0,
      availablePets: json['availablePets'] ?? 0,
      adoptedPets: json['adoptedPets'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      totalRequests: json['totalRequests'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPets': totalPets,
      'availablePets': availablePets,
      'adoptedPets': adoptedPets,
      'pendingRequests': pendingRequests,
      'totalRequests': totalRequests,
    };
  }
}

/// Model pentru cererile de adopție primite (din perspectiva owner-ului)
class AdoptionRequestModel {
  final int id;
  final int petId;
  final String petName;
  final String petType;
  final String? petPhoto;
  final int? applicantId;
  final String? applicantName;
  final String? applicantEmail;
  final String? applicantAvatar;
  final String status;
  final DateTime? applicationDate;
  final DateTime? createdAt;

  // Detalii aplicant
  final String? fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? housingType;
  final bool? hasChildren;
  final bool? hasOtherPets;
  final String? adoptionReason;
  final String? message;

  AdoptionRequestModel({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petType,
    this.petPhoto,
    this.applicantId,
    this.applicantName,
    this.applicantEmail,
    this.applicantAvatar,
    required this.status,
    this.applicationDate,
    this.createdAt,
    this.fullName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.housingType,
    this.hasChildren,
    this.hasOtherPets,
    this.adoptionReason,
    this.message,
  });

  factory AdoptionRequestModel.fromJson(Map<String, dynamic> json) {
    return AdoptionRequestModel(
      id: json['id'],
      petId: json['pet_id'] ?? json['petId'],
      petName: json['pet_name'] ?? json['petName'] ?? '',
      petType: json['pet_type'] ?? json['petType'] ?? '',
      petPhoto: json['pet_photo'] ?? json['petPhoto'],
      applicantId: json['user_id'] ?? json['applicantId'],
      applicantName: json['applicant_name'] ?? json['applicantName'],
      applicantEmail: json['applicant_email'] ?? json['applicantEmail'],
      applicantAvatar: json['applicant_avatar'] ?? json['applicantAvatar'],
      status: json['status'] ?? 'pending',
      applicationDate: json['application_date'] != null
          ? DateTime.parse(json['application_date'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      fullName: json['full_name'] ?? json['fullName'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      housingType: json['housing_type'] ?? json['housingType'],
      hasChildren: json['has_children'] ?? json['hasChildren'],
      hasOtherPets: json['has_other_pets'] ?? json['hasOtherPets'],
      adoptionReason: json['adoption_reason'] ?? json['adoptionReason'],
      message: json['message'],
    );
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'in_review':
        return 'In Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Declined';
      default:
        return status;
    }
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isInReview => status.toLowerCase() == 'in_review';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
}

/// Model pentru răspunsul cu statistici de cereri
class AdoptionRequestsStats {
  final int pending;
  final int inReview;
  final int approved;
  final int rejected;

  AdoptionRequestsStats({
    this.pending = 0,
    this.inReview = 0,
    this.approved = 0,
    this.rejected = 0,
  });

  factory AdoptionRequestsStats.fromJson(Map<String, dynamic> json) {
    return AdoptionRequestsStats(
      pending: json['pending'] ?? 0,
      inReview: json['inReview'] ?? 0,
      approved: json['approved'] ?? 0,
      rejected: json['rejected'] ?? 0,
    );
  }

  int get total => pending + inReview + approved + rejected;
}
