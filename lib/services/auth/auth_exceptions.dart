//LOGIN ERRORS
class InvalidEmailAuthException implements Exception {}

class WrongPasswordAuthEXception implements Exception {}

class UserNotFoundAuthException implements Exception {}

//REGISTER ERRORS
class WeakPasswordAuthException implements Exception {}

class EmailAlreadyInUseAuthEXception implements Exception {}

//GENERAL ERROR
class GeneralAuthException implements Exception {}

class UserNotLoggedInAuthException implements Exception {}
