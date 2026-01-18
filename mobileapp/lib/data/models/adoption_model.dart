// lib/data/models/adoption_model.dart
// Model pentru cererile de adopție

class AdoptionModel {
  final int id;
  final int? userId;
  final int petId;
  final String petName;
  final String petType;
  final String? petBreed;
  final String? petPhoto;
  final String status;
  final DateTime? applicationDate;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? postalCode;
  final String? housingType;
  final String? livingArrangement;
  final String? hasYard;
  final bool? hasChildren;
  final String? children;
  final bool? hasOtherPets;
  final String? otherPets;
  final String? otherPetsDetails;
  final String? previousPetExperience;
  final String? adoptionReason;
  final String? message;
  final String? notes;
  final String? adminNotes;
  final MeetingModel? meeting;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AdoptionModel({
    required this.id,
    this.userId,
    required this.petId,
    required this.petName,
    required this.petType,
    this.petBreed,
    this.petPhoto,
    required this.status,
    this.applicationDate,
    this.fullName,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.postalCode,
    this.housingType,
    this.livingArrangement,
    this.hasYard,
    this.hasChildren,
    this.children,
    this.hasOtherPets,
    this.otherPets,
    this.otherPetsDetails,
    this.previousPetExperience,
    this.adoptionReason,
    this.message,
    this.notes,
    this.adminNotes,
    this.meeting,
    this.createdAt,
    this.updatedAt,
  });

  factory AdoptionModel.fromJson(Map<String, dynamic> json) {
    return AdoptionModel(
      id: json['id'],
      userId: json['user_id'] ?? json['userId'],
      petId: json['pet_id'] ?? json['petId'],
      petName: json['pet_name'] ?? json['petName'] ?? '',
      petType: json['pet_type'] ?? json['petType'] ?? '',
      petBreed: json['pet_breed'] ?? json['petBreed'],
      petPhoto: json['pet_photo'] ?? json['petPhoto'],
      status: json['status'] ?? 'pending',
      applicationDate: json['application_date'] != null
          ? DateTime.parse(json['application_date'])
          : null,
      fullName: json['full_name'] ?? json['fullName'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      postalCode: json['postal_code'] ?? json['postalCode'],
      housingType: json['housing_type'] ?? json['housingType'],
      livingArrangement: json['living_arrangement'] ?? json['livingArrangement'],
      hasYard: json['has_yard'] ?? json['hasYard'],
      hasChildren: json['has_children'] ?? json['hasChildren'],
      children: json['children'],
      hasOtherPets: json['has_other_pets'] ?? json['hasOtherPets'],
      otherPets: json['other_pets'] ?? json['otherPets'],
      otherPetsDetails: json['other_pets_details'] ?? json['otherPetsDetails'],
      previousPetExperience: json['previous_pet_experience'] ?? json['previousPetExperience'],
      adoptionReason: json['adoption_reason'] ?? json['adoptionReason'],
      message: json['message'],
      notes: json['notes'],
      adminNotes: json['admin_notes'] ?? json['adminNotes'],
      meeting: json['meeting'] != null ? MeetingModel.fromJson(json['meeting']) : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Formatează statusul pentru afișare
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'În așteptare';
      case 'in_review':
        return 'În revizuire';
      case 'approved':
        return 'Aprobată';
      case 'rejected':
        return 'Respinsă';
      default:
        return status;
    }
  }

  // Culoarea pentru status
  String get statusColor {
    switch (status) {
      case 'pending':
        return 'orange';
      case 'in_review':
        return 'blue';
      case 'approved':
        return 'green';
      case 'rejected':
        return 'red';
      default:
        return 'grey';
    }
  }

  // Verifică dacă cererea poate fi actualizată
  bool get canUpdate => status == 'pending';

  // Verifică dacă cererea poate fi anulată
  bool get canCancel => status != 'approved';
}

// Model pentru întâlniri programate
class MeetingModel {
  final int id;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String location;
  final String status;
  final String? notes;
  final String? adminMessage;

  MeetingModel({
    required this.id,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.location,
    required this.status,
    this.notes,
    this.adminMessage,
  });

  factory MeetingModel.fromJson(Map<String, dynamic> json) {
    return MeetingModel(
      id: json['id'],
      scheduledDate: DateTime.parse(json['scheduled_date'] ?? json['scheduledDate']),
      scheduledTime: json['scheduled_time'] ?? json['scheduledTime'] ?? '',
      location: json['location'] ?? '',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      adminMessage: json['admin_message'] ?? json['adminMessage'],
    );
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'În așteptare';
      case 'accepted':
        return 'Acceptată';
      case 'rejected':
        return 'Respinsă';
      default:
        return status;
    }
  }
}

// Model pentru răspunsul cu lista de adopții
class AdoptionsResponse {
  final bool success;
  final List<AdoptionModel> applications;
  final PaginationInfo? pagination;

  AdoptionsResponse({
    required this.success,
    required this.applications,
    this.pagination,
  });

  factory AdoptionsResponse.fromJson(Map<String, dynamic> json) {
    return AdoptionsResponse(
      success: json['success'] ?? false,
      applications: json['data']?['applications'] != null
          ? (json['data']['applications'] as List)
              .map((a) => AdoptionModel.fromJson(a))
              .toList()
          : [],
      pagination: json['data']?['pagination'] != null
          ? PaginationInfo.fromJson(json['data']['pagination'])
          : null,
    );
  }
}

// Model pentru paginare (duplicat pentru importuri ușoare)
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      totalItems: json['totalItems'] ?? 0,
      itemsPerPage: json['itemsPerPage'] ?? 20,
    );
  }
}

// Model pentru crearea unei cereri de adopție
class CreateAdoptionRequest {
  final int petId;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String postalCode;
  final String? housingType;
  final String? livingArrangement;
  final String? hasYard;
  final bool? hasChildren;
  final String? children;
  final bool? hasOtherPets;
  final String? otherPets;
  final String? otherPetsDetails;
  final String? previousPetExperience;
  final String adoptionReason;
  final String? message;

  CreateAdoptionRequest({
    required this.petId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.postalCode,
    this.housingType,
    this.livingArrangement,
    this.hasYard,
    this.hasChildren,
    this.children,
    this.hasOtherPets,
    this.otherPets,
    this.otherPetsDetails,
    this.previousPetExperience,
    required this.adoptionReason,
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'petId': petId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'postalCode': postalCode,
      'housingType': housingType,
      'livingArrangement': livingArrangement,
      'hasYard': hasYard,
      'hasChildren': hasChildren,
      'children': children,
      'hasOtherPets': hasOtherPets,
      'otherPets': otherPets,
      'otherPetsDetails': otherPetsDetails,
      'previousPetExperience': previousPetExperience,
      'adoptionReason': adoptionReason,
      'message': message,
    };
  }
}
