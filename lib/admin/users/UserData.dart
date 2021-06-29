
class UserData {
  String uid;
  String displayName;
  String email;
  String phoneNumber;
  String role;
  String lastSignInTime;
  String creationTime;

  UserData();

  UserData.fromJson(var data){
    uid = data['uid'];
    displayName = data['displayName'];
    email = data['email'];
    phoneNumber = data['phoneNumber'];
    role = data['role'];
    lastSignInTime = data['lastSignInTime'];
    creationTime = data['creationTime'];
  }

  toJson(){
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'lastSignInTime': lastSignInTime,
      'creationTime': creationTime,
    };
  }
}