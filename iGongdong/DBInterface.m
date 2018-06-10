//
//  DBInterface.m
//  iMoojigae
//
//  Created by dykim on 2018. 6. 3..
//  Copyright © 2018년 dykim. All rights reserved.
//

#import "DBInterface.h"
#import "sqlite3.h"

@interface DBInterface ()
    @property (copy, nonatomic) NSString *dbPath;
@end

@implementation DBInterface
@synthesize dbPath=_dbPath;

-(NSString *)dbPath
{
    if(!_dbPath)
    {
        NSFileManager *fileman = [NSFileManager defaultManager];
        NSURL *documentPathURL = [[fileman URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSString *databaseFilename =@"gongdong.sqlite";
        
        _dbPath = [[documentPathURL URLByAppendingPathComponent:databaseFilename] path];
        
        [self createTable:_dbPath];
        if(![fileman fileExistsAtPath:_dbPath])
        {
            [self createTable:_dbPath];
//            NSString *dbSource = [[NSBundle mainBundle] pathForResource:@"source" ofType:@"sqlite"];
//            [fileman copyItemAtPath:dbSource toPath:_dbPath error:nil];
        }
    }
    return _dbPath;
}

-(int)createTable:(NSString *)filePath
{
    sqlite3* db = NULL;
    int rc=0;
    
    rc = sqlite3_open_v2([filePath cStringUsingEncoding:NSUTF8StringEncoding], &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL);
    if (SQLITE_OK != rc)
    {
        sqlite3_close(db);
        NSLog(@"Failed to open db connection");
    }
    else
    {
        char * query ="CREATE TABLE IF NOT EXISTS article ( commId TEXT, boardId TEXT, boardNo TEXT, cr_date DATE DEFAULT (datetime('now','localtime')), PRIMARY KEY (commId, boardId, boardNo))";
        char * errMsg;
        rc = sqlite3_exec(db, query,NULL,NULL,&errMsg);
        
        if(SQLITE_OK != rc)
        {
            NSLog(@"Failed to create table rc:%d, msg=%s",rc,errMsg);
        }
        
        sqlite3_close(db);
    }
    return rc;
    
}
-(int)searchWithCommId:(NSString *)commId BoardId:(NSString *)boardId BoardNo:(NSString *)boardNo
{
    int result = 0;
    sqlite3 *db;
    const char *dbfile = [self.dbPath UTF8String];
    if ( sqlite3_open(dbfile, &db) == SQLITE_OK) {
        const char *sql = [[NSString stringWithFormat:@"SELECT count(*) FROM article WHERE commId = \"%@\" AND boardId = \"%@\" AND boardNo = \"%@\";", commId, boardId, boardNo] UTF8String];
        sqlite3_stmt *stmt;
        if( sqlite3_prepare(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
            //Loop through all the returned rows (should be just one)
            while( sqlite3_step(stmt) == SQLITE_ROW )
            {
                result = sqlite3_column_int(stmt, 0);
            }
        } else {
            NSLog( @"Failed from sqlite3_step. Error is:  %s", sqlite3_errmsg(db) );
        }
        sqlite3_finalize(stmt);
        sqlite3_close(db);
    }
    return result;
}

-(void)insertWithCommId:(NSString *)commId BoardId:(NSString *)boardId BoardNo:(NSString *)boardNo
{
    sqlite3 *db;
    if(sqlite3_open([self.dbPath UTF8String], &db) == SQLITE_OK) {
        const char *sql = "INSERT INTO article (commId, boardId, boardNo) VALUES (?, ?, ?)";
        sqlite3_stmt *stmt;
        if( sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
            sqlite3_bind_text(stmt, 1, [commId UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 2, [boardId UTF8String], -1, NULL);
            sqlite3_bind_text(stmt, 3, [boardNo UTF8String], -1, NULL);
            if(sqlite3_step(stmt) != SQLITE_DONE) {
                /* Process Error */
                NSLog( @"Insert Error is:  %s", sqlite3_errmsg(db) );
            }
            sqlite3_finalize(stmt);
        } else {
            NSLog( @"Failed from sqlite3_step. Error is:  %s", sqlite3_errmsg(db) );
        }
        sqlite3_close(db);
    }
}

-(void)delete
{
    sqlite3 *db;
    if(sqlite3_open([self.dbPath UTF8String], &db) == SQLITE_OK) {
        const char *sql = "delete from article where cr_date <= datetime('now', '-6 month', 'localtime')";
        sqlite3_stmt *stmt;
        if( sqlite3_prepare_v2(db, sql, -1, &stmt, NULL) == SQLITE_OK) {
            if(sqlite3_step(stmt) != SQLITE_DONE) {
                /* Process Error */
                NSLog( @"delete Error is:  %s", sqlite3_errmsg(db) );
            }
            sqlite3_finalize(stmt);
        } else {
            NSLog( @"delete from sqlite3_step. Error is:  %s", sqlite3_errmsg(db) );
        }
        sqlite3_close(db);
    }
}

@end
