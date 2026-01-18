// lib/data/models/pet_model.dart
// Model pentru datele animalelor

class PetModel {
  final int id;
  final String name;
  final String type;
  final String? breed;
  final String? ageCategory;
  final String? gender;
  final String? size;
  final String? color;
  final String? coat;
  final double? fee;
  final String? description;
  final String? healthStatus;
  final String? story;
  final String? locationCity;
  final String? locationCountry;
  final String? locationAddress;
  final String? zipCode;
  final String? shelterContactEmail;
  final String? shelterContactPhone;
  final bool isAvailable;
  final String? adoptionStatus;
  final String? primaryPhoto;
  final List<PetPhoto>? photos;
  final List<String>? traits;
  final DateTime? createdAt;

  PetModel({
    required this.id,
    required this.name,
    required this.type,
    this.breed,
    this.ageCategory,
    this.gender,
    this.size,
    this.color,
    this.coat,
    this.fee,
    this.description,
    this.healthStatus,
    this.story,
    this.locationCity,
    this.locationCountry,
    this.locationAddress,
    this.zipCode,
    this.shelterContactEmail,
    this.shelterContactPhone,
    this.isAvailable = true,
    this.adoptionStatus,
    this.primaryPhoto,
    this.photos,
    this.traits,
    this.createdAt,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      breed: json['breed'],
      ageCategory: json['age_category'] ?? json['ageCategory'],
      gender: json['gender'],
      size: json['size'],
      color: json['color'],
      coat: json['coat'],
      fee: json['fee'] != null ? double.tryParse(json['fee'].toString()) : null,
      description: json['description'],
      healthStatus: json['health_status'] ?? json['healthStatus'],
      story: json['story'],
      locationCity: json['location_city'] ?? json['locationCity'],
      locationCountry: json['location_country'] ?? json['locationCountry'],
      locationAddress: json['location_address'] ?? json['locationAddress'],
      zipCode: json['zip_code'] ?? json['zipCode'],
      shelterContactEmail: json['shelter_contact_email'] ?? json['shelterContactEmail'],
      shelterContactPhone: json['shelter_contact_phone'] ?? json['shelterContactPhone'],
      isAvailable: json['is_available'] ?? json['isAvailable'] ?? true,
      adoptionStatus: json['adoption_status'] ?? json['adoptionStatus'],
      primaryPhoto: json['primary_photo'] ?? json['primaryPhoto'],
      photos: json['photos'] != null
          ? (json['photos'] as List).map((p) {
              if (p is String) {
                return PetPhoto(url: p, isPrimary: false);
              }
              return PetPhoto.fromJson(p);
            }).toList()
          : null,
      traits: json['traits'] != null
          ? List<String>.from(json['traits'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'breed': breed,
      'ageCategory': ageCategory,
      'gender': gender,
      'size': size,
      'color': color,
      'coat': coat,
      'fee': fee,
      'description': description,
      'healthStatus': healthStatus,
      'story': story,
      'locationCity': locationCity,
      'locationCountry': locationCountry,
      'isAvailable': isAvailable,
      'adoptionStatus': adoptionStatus,
      'primaryPhoto': primaryPhoto,
      'photos': photos?.map((p) => p.toJson()).toList(),
      'traits': traits,
    };
  }

  // Obține URL-ul imaginii principale
  String get imageUrl {
    if (primaryPhoto != null && primaryPhoto!.isNotEmpty) {
      return primaryPhoto!;
    }
    if (photos != null && photos!.isNotEmpty) {
      return photos!.first.url;
    }
    return 'https://via.placeholder.com/300x300?text=No+Image';
  }

  // Obține lista de URL-uri pentru galerie
  List<String> get galleryUrls {
    if (photos != null && photos!.isNotEmpty) {
      return photos!.map((p) => p.url).toList();
    }
    if (primaryPhoto != null && primaryPhoto!.isNotEmpty) {
      return [primaryPhoto!];
    }
    return [];
  }

  // Formatează vârsta pentru afișare
  String get ageDisplay {
    switch (ageCategory) {
      case 'puppy':
        return 'Pui';
      case 'young':
        return 'Tânăr';
      case 'adult':
        return 'Adult';
      case 'senior':
        return 'Senior';
      default:
        return ageCategory ?? 'Necunoscut';
    }
  }

  // Formatează genul pentru afișare
  String get genderDisplay {
    switch (gender) {
      case 'male':
        return 'Mascul';
      case 'female':
        return 'Femelă';
      default:
        return gender ?? 'Necunoscut';
    }
  }

  // Formatează mărimea pentru afișare
  String get sizeDisplay {
    switch (size) {
      case 'small':
        return 'Mic';
      case 'medium':
        return 'Mediu';
      case 'large':
        return 'Mare';
      default:
        return size ?? 'Necunoscut';
    }
  }

  // Formatează locația pentru afișare
  String get locationDisplay {
    final parts = <String>[];
    if (locationCity != null && locationCity!.isNotEmpty) {
      parts.add(locationCity!);
    }
    if (locationCountry != null && locationCountry!.isNotEmpty) {
      parts.add(locationCountry!);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Locație necunoscută';
  }
}

// Model pentru fotografiile animalelor
class PetPhoto {
  final int? id;
  final String url;
  final bool isPrimary;

  PetPhoto({
    this.id,
    required this.url,
    this.isPrimary = false,
  });

  factory PetPhoto.fromJson(Map<String, dynamic> json) {
    return PetPhoto(
      id: json['id'],
      url: json['url'] ?? json['photo_url'] ?? '',
      isPrimary: json['is_primary'] ?? json['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'isPrimary': isPrimary,
    };
  }
}

// Model pentru răspunsul cu lista de animale
class PetsResponse {
  final bool success;
  final List<PetModel> pets;
  final PaginationInfo? pagination;

  PetsResponse({
    required this.success,
    required this.pets,
    this.pagination,
  });

  factory PetsResponse.fromJson(Map<String, dynamic> json) {
    return PetsResponse(
      success: json['success'] ?? false,
      pets: json['data']?['pets'] != null
          ? (json['data']['pets'] as List)
              .map((p) => PetModel.fromJson(p))
              .toList()
          : [],
      pagination: json['data']?['pagination'] != null
          ? PaginationInfo.fromJson(json['data']['pagination'])
          : null,
    );
  }
}

// Model pentru informații de paginare
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

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;
}
