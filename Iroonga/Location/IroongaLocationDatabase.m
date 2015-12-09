//
//  IroongaLocationDatabase.m
//
//  Created by goccy on 2015/09/06.
//  Copyright (c) 2015年 goccy. All rights reserved.
//

#import "IroongaLocationDatabase.h"
#include <groonga.h>
#include <grn_str.h>
#include <grn_geo.h>
#import "IroongaLocationTable.h"

@interface IroongaLocationDatabase()

@property(nonatomic) grn_obj *db;

@end

static grn_ctx *g_ctx = NULL;

@implementation IroongaLocationDatabase

- (instancetype)init
{
    self = [super init];
    if (g_ctx) return self;
    
    if (grn_init()) {
        NSLog(@"[ERROR] failed grn_init().");
        return nil;
    }
    g_ctx = grn_ctx_open(0);
    return self;
}

- (instancetype)initWithName:(NSString *)name
{
    self      = [self init];
    self.name = name;
    return self;
}

+ (instancetype)createWithName:(NSString *)name
{
    IroongaLocationDatabase *instance = [[IroongaLocationDatabase alloc] initWithName:name];
    instance.db = [instance openOrCreateDatabase:name];
    return instance;
}

- (void)drop
{
    NSError *error = nil;
    NSString *databaseRoot = [self databaseRootDirectory];
    [[NSFileManager defaultManager] removeItemAtPath:databaseRoot error:&error];
    if (error) {
        NSLog(@"[ERROR] cannot remove directory. [%@]", [error description]);
    }
}

- (BOOL)isAlreadyCreated
{
    return grn_db_open(g_ctx, [[self databasePath:self.name] UTF8String]) ? YES : NO;
}

- (NSString *)commonDatabasePath
{
    return [NSString stringWithFormat:@"%@iroonga", NSTemporaryDirectory()];
}

- (NSString *)databaseRootDirectory
{
    return [NSString stringWithFormat:@"%@/%@", [self commonDatabasePath], self.name];
}

- (NSString *)databasePath:(NSString *)name
{
    return [NSString stringWithFormat:@"%@/%@.groonga", [self databaseRootDirectory], name];
}

- (void)createPathIfNoExists:(NSString *)path
{
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];
    if (error) {
        NSLog(@"[ERROR] cannot create directory. [%@]", [error description]);
    }
}

- (grn_obj *)openOrCreateDatabase:(NSString *)name
{
    NSString *dbPath = [self databasePath:name];
    [self createPathIfNoExists:[self databaseRootDirectory]];
    grn_obj *db = NULL;
    GRN_DB_OPEN_OR_CREATE(g_ctx, [dbPath UTF8String], NULL, db);
    return db;
}

- (IroongaLocationTable *)createTableWithName:(NSString *)name
{
    return [IroongaLocationTable createTableWithCTX:g_ctx withName:name withTableType:IroongaTableTypeHash withTableKeyType:IroongaTableKeyTypeShortText];
}

- (IroongaLocationTable *)tableWithName:(NSString *)name indexColumnName:(NSString *)columnName
{
    NSString *dbPath = [self databasePath:self.name];
    grn_obj *db      = grn_db_open(g_ctx, [dbPath UTF8String]);
    (void)db;
    IroongaLocationTable *instance = [[IroongaLocationTable alloc] initWithCTX:g_ctx withName:name];
    [instance loadLocationIndexTableWithName:name withColumnName:columnName];
    return instance;
}

@end
