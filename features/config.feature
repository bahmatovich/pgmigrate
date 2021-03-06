Feature: Getting info from config

    Scenario: Callbacks from config are executed in correct order
        Given migration dir
        And migrations
           | file                      | code                                                 |
           | V1__Single_migration.sql  | INSERT INTO mycooltable (op) values ('Migration 1'); |
           | V2__Another_migration.sql | INSERT INTO mycooltable (op) values ('Migration 2'); |
       And config callbacks
           | type       | file            | code                                                        |
           | beforeAll  | before_all.sql  | CREATE TABLE mycooltable (seq SERIAL PRIMARY KEY, op TEXT); |
           | beforeEach | before_each.sql | INSERT INTO mycooltable (op) values ('Before each');        |
           | afterEach  | after_each.sql  | INSERT INTO mycooltable (op) values ('After each');         |
           | afterAll   | after_all.sql   | INSERT INTO mycooltable (op) values ('After all');          |
        And database and connection
        When we run pgmigrate with "-t 2 migrate"
        Then pgmigrate command "succeeded"
        And database contains schema_version
        And query "SELECT * from mycooltable order by seq;" equals
            | seq | op          |
            | 1   | Before each |
            | 2   | Migration 1 |
            | 3   | After each  |
            | 4   | Before each |
            | 5   | Migration 2 |
            | 6   | After each  |
            | 7   | After all   |

    Scenario: Callbacks from config are executed from dir
        Given migration dir
        And migrations
           | file                     | code                                                        |
           | V1__Single_migration.sql | CREATE TABLE mycooltable (seq SERIAL PRIMARY KEY, op TEXT); |
       And config callbacks
           | type     | dir       | file         | code                                               |
           | afterAll | after_all | callback.sql | INSERT INTO mycooltable (op) values ('After all'); |
        And database and connection
        When we run pgmigrate with "-t 2 migrate"
        Then pgmigrate command "succeeded"
        And database contains schema_version
        And query "SELECT * from mycooltable order by seq;" equals
           | seq | op        |
           | 1   | After all |

    Scenario: Callbacks from config are overrided by args
        Given migration dir
        And migrations
           | file                     | code                                                        |
           | V1__Single_migration.sql | CREATE TABLE mycooltable (seq SERIAL PRIMARY KEY, op TEXT); |
       And config callbacks
           | type    | file         | code      |
           | INVALID | callback.sql | SELECT 1; |
       And callbacks
           | type     | file          | code                                               |
           | afterAll | after_all.sql | INSERT INTO mycooltable (op) values ('After all'); |
        And database and connection
        When we run pgmigrate with our callbacks and "-t 2 migrate"
        Then pgmigrate command "succeeded"
        And database contains schema_version
        And query "SELECT * from mycooltable order by seq;" equals
           | seq | op        |
           | 1   | After all |
