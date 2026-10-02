class ProfileModel {
  final String id;
  final String linkImageCover;
  final String linkImageProfile;
  final String name;
  final String dateBirth;
  final String race;
  final String placeBirth;
  final String placeLive;
  final double numberFollowing;
  final double numberFollowers;
  ProfileModel({
    required this.id,
    required this.linkImageCover,
    required this.linkImageProfile,
    required this.name,
    required this.dateBirth,
    required this.race,
    required this.placeBirth,
    required this.placeLive,
    required this.numberFollowing,
    required this.numberFollowers,
});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id' : id,
      'linkImageCover' : linkImageCover,
      'linkImageProfile' : linkImageProfile,
      'name' : name,
      'dateBirth' : dateBirth,
      'race' : race,
      'placeBirth' : placeBirth,
      'placeLive' : placeLive,
      'numberFollowing' : numberFollowing,
      'numberFollowers' : numberFollowers,
    };
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
        linkImageCover: map['linkImageCover'] as String,
        linkImageProfile: map['linkImageProfile'] as String,
        name: map['name'] as String,
        dateBirth: map['dateBirth'] as String,
        race: map['race'] as String,
        placeBirth: map['placeBirth'],
        placeLive: map['placeLive'] as String,
        numberFollowing: double.tryParse(map['numberFollowing'].toString()) ?? 0,
        numberFollowers: double.tryParse(map['numberFollowers'].toString()) ?? 0,
    );
  }

}