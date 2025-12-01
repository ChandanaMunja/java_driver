class DocumentModel {
  bool? backSide;
  bool? enable;
  bool? expireAt;
  String? id;
  bool? frontSide;
  String? title;

  DocumentModel({this.backSide, this.enable, this.id, this.frontSide, this.title, this.expireAt});

  DocumentModel.fromJson(Map<String, dynamic> json) {
    backSide = json['backSide'] == 1;
    enable = json['enable'] == 1;
    frontSide = json['frontSide'] == 1;
    id = json['id'];
    title = json['title'];
    expireAt = json['expireAt'] == 1; // if DB also returns int
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['backSide'] = backSide;
    data['enable'] = enable;
    data['id'] = id;
    data['frontSide'] = frontSide;
    data['title'] = title;
    data['expireAt'] = expireAt;
    return data;
  }
}
