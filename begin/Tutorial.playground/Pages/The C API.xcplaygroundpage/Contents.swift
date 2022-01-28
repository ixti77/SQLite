

import Foundation
import SQLite3
import PlaygroundSupport

destroyPart1Database()

/*:
 
 # Getting Started
 
 The first thing to do is set your playground to run manually rather than automatically. This will help ensure that your SQL commands run when you intend them to. At the bottom of the playground click and hold the Play button until the dropdown menu appears. Choose "Manually Run".
 
 You will also notice a `destroyPart1Database()` call at the top of this page. You can safely ignore this, the database file used is destroyed each time the playground is run to ensure all statements execute successfully as you iterate through the tutorial.
 
 */


//: ## Open a Connection
func openDatabase() -> OpaquePointer? {
	var db: OpaquePointer?
	guard let part1DbPath = part1DbPath else {
		print("part1DbPath is nil")
		return nil
	}
	if sqlite3_open(part1DbPath, &db) == SQLITE_OK {
		print("Successfully opened connection to database at \(part1DbPath)")
		return db
	} else {
		print("Unable to open database.")
		PlaygroundPage.current.finishExecution()
	}
}

let db = openDatabase()
//: ## Create a Table
let createTableString = """
CREATE TABLE Contact(
Id INT PRIMARY KEY NOT NULL,
Name CHAR(255));
"""

func createTable() {
	var createTableStatement: OpaquePointer?
	
	if sqlite3_prepare_v2(
		db,
		createTableString,
		-1,
		&createTableStatement,
		nil
	) == SQLITE_OK {
		if sqlite3_step(createTableStatement) == SQLITE_DONE {
			print("\nContact table created.")
		} else {
			print("\nContact table is not created.")
		}
	} else {
		print("\nCREATE TABLE statement is not prepared.")
	}
	
	sqlite3_finalize(createTableStatement)
}

createTable()
//: ## Insert a Contact
let insertStatementString = "INSERT INTO Contact (Id, Name) VALUES (?, ?);"

func insert() {
	var insertStatement: OpaquePointer?
	
	if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
		let contacts: [NSString] = [
			"Ray",
			"Maysara",
			"Ikhtiyor"
		]
		
		for (index, name) in contacts.enumerated() {
			let id = Int32(index + 1)
			
			sqlite3_bind_int(insertStatement, 1, id)
			sqlite3_bind_text(insertStatement, 2, name.utf8String, -1, nil)
			
			if sqlite3_step(insertStatement) == SQLITE_DONE {
				print("\nSuccessfully inserted row.")
			} else {
				print("\nCould not insert row.")
			}
			
			sqlite3_reset(insertStatement)
		}
		
		sqlite3_finalize(insertStatement)
	} else {
		print("\nINSERT statement is not prepared.")
	}
}

insert()
//: ## Challenge - Multiple Inserts

//: ## Querying
//let queryStatementString = "SELECT * FROM Contact;"
//
//func query() {
//	var queryStatement: OpaquePointer?
//
//	if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
//		if sqlite3_step(queryStatement) == SQLITE_ROW {
//			let id = sqlite3_column_int(queryStatement, 0)
//
//			guard
//				let queryResultCol1 = sqlite3_column_text(queryStatement, 1)
//			else {
//				print("Query result is nil")
//				return
//			}
//
//			let name = String(cString: queryResultCol1)
//
//			print("\nQuery Result:")
//			print("\(id) | \(name)")
//		} else {
//			print("\nQuery returned no results.")
//		}
//	} else {
//		let errorMessage = String(cString: sqlite3_errmsg(db))
//		print("\nQuery is not prepared \(errorMessage)")
//	}
//
//	sqlite3_finalize(queryStatement)
//}
//
//query()
//: ## Challenge - Querying multiple rows
let queryStatementString = "SELECT * FROM Contact;"

func query() {
	var queryStatement: OpaquePointer?
	if sqlite3_prepare_v2(
		db,
		queryStatementString,
		-1,
		&queryStatement,
		nil
	) == SQLITE_OK {
		print("\n")
		while (sqlite3_step(queryStatement) == SQLITE_ROW) {
			let id = sqlite3_column_int(queryStatement, 0)
			guard
				let queryResultCol1 = sqlite3_column_text(queryStatement, 1)
			else {
				print("Query result is nil.")
				return
			}
			let name = String(cString: queryResultCol1)
			print("Query Result:")
			print("\(id) | \(name)")
		}
	} else {
		let errorMessage = String(cString: sqlite3_errmsg(db))
		print("\nQuery is not prepared \(errorMessage)")
	}
	sqlite3_finalize(queryStatement)
}

query()
//: ## Update
let updateStatementString = "UPDATE Contact SET Name = 'Adam' WHERE Id = 1;"

func update() {
	var updateStatement: OpaquePointer?
	
	if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
		if sqlite3_step(updateStatement) == SQLITE_DONE {
			print("\nSuccessfully updated row.")
		} else {
			print("\nCould not update row.")
		}
	} else {
		print("\nUPDATE statement is not prepared")
	}
	
	sqlite3_finalize(updateStatement)
}

update()
query()
//: ## Delete
let deleteStatementString = "DELETE FROM Contact WHERE Id = 1;"

func delete() {
	var deleteStatement: OpaquePointer?
	
	if sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK {
		if sqlite3_step(deleteStatement) == SQLITE_DONE {
			print("\nSuccessfully deleted row.")
		} else {
			print("\nCould not delete row.")
		}
	} else {
		print("\nDELETE statement could not be prepared")
	}
}

delete()
query()

//let malformedQueryString = "SELECT Stuff from Things WHERE Whatever;"
//
//func prepareMalformedQuery() {
//	var malformedStatement: OpaquePointer?
//
//	if sqlite3_prepare_v2(db, malformedQueryString, -1, &malformedStatement, nil) == SQLITE_OK {
//		print("\nThis should not have happened.")
//	} else {
//		let errorMessage = String(cString: sqlite3_errmsg(db))
//		print("\nQuery is not prepared! \(errorMessage)")
//	}
//
//	sqlite3_finalize(malformedStatement)
//}
//
//prepareMalformedQuery()
//: ## Close the database connection
sqlite3_close_v2(db)
//: Continue to [Making It Swift](@next)

