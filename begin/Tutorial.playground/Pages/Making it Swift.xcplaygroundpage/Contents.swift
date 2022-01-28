import Foundation
import SQLite3
import PlaygroundSupport

destroyPart2Database()
//: # Making it Swift
protocol SQLTable {
	static var createStatement: String { get }
}

enum SQLiteError: Error {
	case OpenDatabase(message: String)
	case Prepare(message: String)
	case Step(message: String)
	case Bind(message: String)
}
//: ## The Database Connection
class SQLiteDatabase {
	private let dbPointer: OpaquePointer?
	
	fileprivate var errorMessage: String {
		if let errorPointer = sqlite3_errmsg(dbPointer) {
			let errorMessage = String(cString: errorPointer)
			return errorMessage
		} else {
			return "No error message provided from sqlite."
		}
	}
	
	private init(dbPointer: OpaquePointer?) {
		self.dbPointer = dbPointer
	}
	
	deinit {
		sqlite3_close(dbPointer)
	}
	
	static func open(path: String) throws -> SQLiteDatabase {
		var db: OpaquePointer?
		
		if sqlite3_open(path, &db) == SQLITE_OK {
			return SQLiteDatabase(dbPointer: db)
		} else {
			defer {
				if db != nil {
					sqlite3_close(db)
				}
			}
			
			if let errorPointer = sqlite3_errmsg(db) {
				let message = String(cString: errorPointer)
				throw SQLiteError.OpenDatabase(message: message)
			} else {
				throw SQLiteError.OpenDatabase(message: "No error message provided from sqlite.")
			}
		}
	}
}

let db: SQLiteDatabase

do {
	db = try SQLiteDatabase.open(path: part2DbPath ?? "")
	print("Successfully opened connection to database.")
} catch SQLiteError.OpenDatabase(_) {
	print("Unable to open database.")
	PlaygroundPage.current.finishExecution()
}
//: ## Preparing Statements
extension SQLiteDatabase {
	func prepareStatement(sql: String) throws -> OpaquePointer? {
		var statement: OpaquePointer?
		
		guard
			sqlite3_prepare_v2(
				dbPointer,
				sql,
				-1,
				&statement,
				nil
			) == SQLITE_OK
		else {
			throw SQLiteError.Prepare(message: errorMessage)
		}
		
		return statement
	}
}

struct Contact {
	let id: Int32
	let name: NSString
}

extension Contact: SQLTable {
	static var createStatement: String {
		return """
			CREATE TABLE Contact(
				Id INT PRIMARY KEY NOT NULL,
				NAME CHAR(255)
			);
		"""
	}
}
//: ## Create Table
extension SQLiteDatabase {
	func createTable(table: SQLTable.Type) throws {
		let createTableStatement = try prepareStatement(sql: table.createStatement)
		
		defer {
			sqlite3_finalize(createTableStatement)
		}
		
		guard
			sqlite3_step(createTableStatement) == SQLITE_DONE
		else {
			throw SQLiteError.Step(message: errorMessage)
		}
		
		print("\(table) table created.")
	}
}

do {
	try db.createTable(table: Contact.self)
} catch {
	print(db.errorMessage)
}

extension SQLiteDatabase {
  func insertContact(contact: Contact) throws {
	let insertSql = "INSERT INTO Contact (Id, Name) VALUES (?, ?);"
	let insertStatement = try prepareStatement(sql: insertSql)
	defer {
	  sqlite3_finalize(insertStatement)
	}
	let name: NSString = contact.name
	guard
	  sqlite3_bind_int(insertStatement, 1, contact.id) == SQLITE_OK  &&
	  sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil)
		== SQLITE_OK
	  else {
		throw SQLiteError.Bind(message: errorMessage)
	}
	guard sqlite3_step(insertStatement) == SQLITE_DONE else {
	  throw SQLiteError.Step(message: errorMessage)
	}
	print("Successfully inserted row.")
  }
}


do {
  try db.insertContact(contact: Contact(id: 1, name: "Ray"))
} catch {
  print(db.errorMessage)
}

//: ## Read
extension SQLiteDatabase {
  func contact(id: Int32) -> Contact? {
	let querySql = "SELECT * FROM Contact WHERE Id = ?;"
	guard let queryStatement = try? prepareStatement(sql: querySql) else {
	  return nil
	}
	defer {
	  sqlite3_finalize(queryStatement)
	}
	guard sqlite3_bind_int(queryStatement, 1, id) == SQLITE_OK else {
	  return nil
	}
	guard sqlite3_step(queryStatement) == SQLITE_ROW else {
	  return nil
	}
	let id = sqlite3_column_int(queryStatement, 0)
	guard let queryResultCol1 = sqlite3_column_text(queryStatement, 1) else {
	  print("Query result is nil.")
	  return nil
	}
	let name = String(cString: queryResultCol1) as NSString
	return Contact(id: id, name: name)
  }
}

if let first = db.contact(id: 1) {
  print("\(first.id) \(first.name)")
}

