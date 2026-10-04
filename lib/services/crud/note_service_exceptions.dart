abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
  @override
  String toString() => message;
}

// --- Database/infrastructure-level ---
abstract class AppDatabaseException extends AppException {
  const AppDatabaseException(super.message);
}

class DatabaseNotOpenException extends AppDatabaseException {
  const DatabaseNotOpenException() : super('Database is not open');
}

class DatabaseInitException extends AppDatabaseException {
  const DatabaseInitException(super.message);
}

class DatabaseOperationException extends AppDatabaseException {
  const DatabaseOperationException(super.message);
}

//Cloud exceptions
abstract class AppSyncException extends AppException {
  const AppSyncException(super.message);
}

class CloudSyncException extends AppSyncException {
  const CloudSyncException(super.message);
}

// --- User domain ---
abstract class UserException extends AppException {
  const UserException(super.message);
}

class UserAlreadyExistsException extends UserException {
  const UserAlreadyExistsException(super.message);
}

class UserDoesntExistException extends UserException {
  const UserDoesntExistException(super.message);
}

class UserMismatchException extends UserException {
  const UserMismatchException(super.message);
}

// --- Note domain ---
abstract class NoteException extends AppException {
  const NoteException(super.message);
}

class NoteNotPresentException extends NoteException {
  const NoteNotPresentException(super.message);
}

class CouldntUpdateNoteException extends NoteException {
  const CouldntUpdateNoteException(super.message);
}
