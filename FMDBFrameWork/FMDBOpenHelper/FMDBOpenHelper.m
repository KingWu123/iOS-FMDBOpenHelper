//
//  FMDBOpenHelper.m
//  FMDBFrameWork
//
//  Created by king.wu on 7/21/16.
//  Copyright © 2016 king.wu. All rights reserved.
//

#define mustOverride(__PRETTY_FUNCTION__) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"%@ must be overridden in a subclass/category", __PRETTY_FUNCTION__] userInfo:nil]

#define FMDB_OPENHELPER_TAG @"FMDBOpenHelper_tag"




#import "FMDBOpenHelper.h"


@interface FMDBOpenHelper()

@property (nonatomic, strong) NSString *dbPath;
@property (nonatomic, strong) NSString *dbName;
@property (nonatomic, assign) int newVersion;
@property (nonatomic, strong) FMDatabaseQueue *databaseQueue;

@end

@implementation FMDBOpenHelper

/**
 *  Create a openHelper object to create, open, and/or manage a database.
 *  the dataBase is not actually created or opened until  @{link #getFMDatabase} is called.
 *
 *
 *  @param dbName  databse name
 *  @param version  number of the database (starting at 1), 
 *     if db first create, @{link #onCreate}  will be called;
 *     if new version > current Version, @{link #onUpgrade} will be used to upgrade the database;
 *     if new version < current version, @{link #onDowngrade} will be used to downgrade the database
 *
 *  @return the FMDBOpenHelper
 */
- (instancetype)initOpenHelper:(NSString *)dbName version:(int)version{
    
    self = [super init];
    if (self){
        self.dbName = dbName;
        self.newVersion = version;
        
        //init db path
        NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        docsPath = [docsPath stringByAppendingPathComponent:@"sqlite"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:docsPath]){
            [[NSFileManager defaultManager] createDirectoryAtPath:docsPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        self.dbPath = [docsPath stringByAppendingPathComponent:dbName];
    }
    return self;
}


/**
 *  Return the name of the FMDatabase being opened, as given to
 *  the constructor
 *
 *  @return database name
 */
- (NSString *)databaseName{
    return self.dbName;
}


/**
 * Create and/or open a database that will be used for reading and writing.
 * The first time this is called, the database will be opened and
 * {@link #onCreate}, {@link #onUpgrade} and/or {@link #onOpen} will be
 * called.
 *
 * <p>Once opened successfully, the database is cached, so you can
 * call this method every time you need to write to the database.
 * (Make sure to call {@link #close} when you no longer need the database.)
 * Errors such as bad permissions or a full disk may cause this method
 * to fail, but future attempts may succeed if the problem is fixed.</p>
 *
 * Database upgrade may take a long time, you
 * should not call this method from the application main thread.
 *
 *  @return the FMDatabaseQueue
 */
-  (FMDatabaseQueue *)getFMDatabaseQueue{
    
    @synchronized (self) {
        if (self.databaseQueue != nil){
            return self.databaseQueue;
        }
        
        //queue will open a FMDatabase inner.
        self.databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.dbPath];
        
        
        int oldVersion = [self databaseVersion];
        
        if (oldVersion != self.newVersion){
           
            if (oldVersion == 0){
                [self onCreate:self.databaseQueue];
            }else{
                if (oldVersion < self.newVersion){
                    [self onUpgrade:self.databaseQueue oldVersion:oldVersion newVersion:self.newVersion];
                }else{
                    [self onDowngrade:self.databaseQueue oldVersion:oldVersion newVersion:self.newVersion];
                }
            }
           
            
            [self setDatabseVersion:self.newVersion];
        }
        
        return self.databaseQueue;
    }
}

/**
 *  close the FMdatabse
 */
- (void)close{
    @synchronized (self) {
        if (self.databaseQueue != nil){
            [self.databaseQueue close];
        }
    }
}






/**
 * Called when th database is created for the first time. This is where the
 * create of tables and the initial population of the tables shoud happen.
 *
 * subclass must implement it
 *
 *  @param dbQueue the FMDatabaseQueue
 */
- (void)onCreate:(FMDatabaseQueue *)dbQueue{
    mustOverride(@"FMDBOpenHelper onCreate");
}


/**
 * Called when the database needs to be upgraded. The implementation
 * should use this method to drop tables, add tables, or do anything else it
 * needs to upgrade to the new schema version.
 *
 * If you add new columns
 * you can use ALTER TABLE to insert them into a live table. If you rename or remove columns
 * you can use ALTER TABLE to rename the old table, then create the new table and then
 * populate the new table with the contents of the old table.
 *
 * This method executes within a transaction.  If an exception is thrown, all changes
 * will automatically be rolled back.
 *
 * subclass must implement it
 *
 *  @param dbQueue    the FMDatabaseQueue
 *  @param oldVersion the old version
 *  @param newVersion the new version
 */
- (void)onUpgrade:(FMDatabaseQueue*)dbQueue  oldVersion:(int)oldVersion newVersion:(int)newVersion{
   mustOverride(@"FMDBOpenHelper onUpgrade");
}


/**
 * Called when the database needs to be downgraded. This is strictly similar to
 * {@link #onUpgrade} method, but is called whenever current version is newer than requested one.
 * However, this method is not abstract, so it is not mandatory for a customer to
 * implement it. If not overridden, default implementation will reject downgrade and
 * throws SQLiteException
 *
 * This method executes within a transaction.  If an exception is thrown, all changes
  * will automatically be rolled back.
 *
 *  @param dbQueue    the FMDatabase
 *  @param oldVersion thd old version
 *  @param newVersion the new version
 */
- (void)onDowngrade:(FMDatabaseQueue*)dbQueue  oldVersion:(int)oldVersion newVersion:(int)newVersion{
    
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                reason:[NSString stringWithFormat:@"Can't downgrade database from version %d to %d", oldVersion, newVersion]
                                userInfo:nil];
}


#pragma mark - private method

- (int)databaseVersion{
    
    __block int version;
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
       
         version = [db userVersion];
    }];
    
    return version;
    
    
//    NSDictionary *dbVersionDc = [[NSUserDefaults standardUserDefaults] objectForKey:@"readerDBVersion"];
//    int version = [[dbVersionDc objectForKey:self.dbName] intValue];
//    return version;
}

- (void)setDatabseVersion:(int)version{
    
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        [db setUserVersion:version];
    }];
    
//    NSMutableDictionary *dbVersionDc = [[NSMutableDictionary alloc]initWithDictionary: [[NSUserDefaults standardUserDefaults] objectForKey:@"readerDBVersion"]];
//    
//    [dbVersionDc setObject:@(version) forKey:self.dbName];
//    
//    [[NSUserDefaults standardUserDefaults] setObject:dbVersionDc forKey:@"readerDBVersion"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
