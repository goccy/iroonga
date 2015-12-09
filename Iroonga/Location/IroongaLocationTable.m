//
//  IroongaLocationTable.m
//
//  Created by goccy on 2015/09/06.
//  Copyright (c) 2015年 goccy. All rights reserved.
//

#import "IroongaLocationTable.h"
#include <groonga.h>
#include <grn_str.h>
#include <grn_geo.h>
#import "IroongaLocationDatabase.h"

#if DEBUG
#define DEBUG_LOG(...) NSLog(__VA_ARGS__)
#else
#define DEBUG_LOG(...)
#endif

@interface IroongaRecordArgument : NSObject

@property(nonatomic) grn_id recordId;
@property(nonatomic) grn_obj *table;
@property(nonatomic) NSString *columnName;

@end

@implementation IroongaRecordArgument

@end


@interface IroongaLocationTable()

@property(nonatomic) grn_ctx *ctx;
@property(nonatomic) grn_obj *handler;
@property(nonatomic) IroongaLocationTable *indexTable;
@property(nonatomic) NSMutableDictionary *columnData;

@end

@implementation IroongaLocationTable

- (NSString *)tableTypeToString:(IroongaTableType)type
{
    NSString *ret = nil;
    switch (type) {
        case IroongaTableTypeHash:
            ret = @"TABLE_HASH_KEY";
            break;
        case IroongaTableTypePat:
            ret = @"TABLE_PAT_KEY";
            break;
        case IroongaTableTypeDat:
            ret = @"TABLE_DAT_KEY";
            break;
        case IroongaTableTypeNo:
            ret = @"TABLE_NO_KEY";
            break;
        default:
            break;
    }
    return ret;
}

- (NSString *)tableKeyTypeToString:(IroongaTableKeyType)type
{
    NSString *ret = nil;
    switch (type) {
        case IroongaTableKeyTypeObject:
            ret = @"Object";
            break;
        case IroongaTableKeyTypeBool:
            ret = @"Bool";
            break;
        case IroongaTableKeyTypeFloat:
            ret = @"Float";
            break;
        case IroongaTableKeyTypeInt16:
            ret = @"Int16";
            break;
        case IroongaTableKeyTypeInt32:
            ret = @"Int32";
            break;
        case IroongaTableKeyTypeInt64:
            ret = @"Int64";
            break;
        case IroongaTableKeyTypeInt8:
            ret = @"Int8";
            break;
        case IroongaTableKeyTypeLongText:
            ret = @"LongText";
            break;
        case IroongaTableKeyTypeShortText:
            ret = @"ShortText";
            break;
        case IroongaTableKeyTypeText:
            ret = @"Text";
            break;
        case IroongaTableKeyTypeTime:
            ret = @"Time";
            break;
        case IroongaTableKeyTypeTokyoGeoPoint:
            ret = @"TokyoGeoPoint";
            break;
        case IroongaTableKeyTypeUInt16:
            ret = @"UInt16";
            break;
        case IroongaTableKeyTypeUInt32:
            ret = @"UInt32";
            break;
        case IroongaTableKeyTypeUInt64:
            ret = @"UInt64";
            break;
        case IroongaTableKeyTypeUInt8:
            ret = @"UInt8";
            break;
        case IroongaTableKeyTypeWGS84GeoPoint:
            ret = @"WGS84GeoPoint";
            break;
        default:
            break;
    }
    return ret;
}

- (NSString *)columnTypeToString:(IroongaColumnType)columnType
{
    NSMutableArray *types = [@[] mutableCopy];
    if (columnType & IroongaColumnTypeScalar) {
        [types addObject:@"COLUMN_SCALAR"];
    }
    if (columnType & IroongaColumnTypeVector) {
        [types addObject:@"COLUMN_VECTOR"];
    }
    if (columnType & IroongaColumnTypeIndex) {
        [types addObject:@"COLUMN_INDEX"];
    }
    if (columnType & IroongaColumnTypeCompressZlib) {
        [types addObject:@"COMPRESS_ZLIB"];
    }
    if (columnType & IroongaColumnTypeCompressLZO) {
        [types addObject:@"COMPRESS_LZO"];
    }
    if (columnType & IroongaColumnTypeWithSection) {
        [types addObject:@"WITH_SECTION"];
    }
    if (columnType & IroongaColumnTypeWithWeight) {
        [types addObject:@"WITH_WEIGHT"];
    }
    if (columnType & IroongaColumnTypeWithPosition) {
        [types addObject:@"WITH_POSITION"];
    }
    return [types componentsJoinedByString:@"|"];
}

+ (instancetype)createTableWithCTX:(grn_ctx *)ctx withName:(NSString *)name withTableType:(IroongaTableType)tableType withTableKeyType:(IroongaTableKeyType)tableKeyType
{
    IroongaLocationTable *table = [[IroongaLocationTable alloc] init];
    table.ctx                   = ctx;
    table.columnData            = [@{} mutableCopy];
    table.name                  = name;
    
    grn_obj *command    = grn_ctx_get(ctx, "table_create", strlen("table_create"));
    grn_obj *nameObj    = grn_expr_get_var(ctx, command, "name", strlen("name"));
    grn_obj *flagsObj   = grn_expr_get_var(ctx, command, "flags", strlen("flags"));
    grn_obj *keyTypeObj = grn_expr_get_var(ctx, command, "key_type", strlen("key_type"));
    
    GRN_TEXT_PUTS(ctx, nameObj,  [name UTF8String]);
    GRN_TEXT_PUTS(ctx, flagsObj, [[table tableTypeToString:tableType] UTF8String]);
    GRN_TEXT_PUTS(ctx, keyTypeObj, [[table tableKeyTypeToString:tableKeyType] UTF8String]);
    
    grn_expr_exec(ctx, command, 0);
    
    DEBUG_LOG(@"table_create %@ %@ %@", name, [table tableTypeToString:tableType], [table tableKeyTypeToString:tableKeyType]);

    return table;
}

- (instancetype)initWithCTX:(grn_ctx *)ctx withName:(NSString *)name
{
    IroongaLocationTable *table = [[IroongaLocationTable alloc] init];
    table.ctx                   = ctx;
    table.name                  = name;
    table.columnData            = [@{} mutableCopy];
    [table loadHandler];
    return table;
}

- (void)loadHandler
{
    self.handler = grn_ctx_get(self.ctx, [self.name UTF8String], (int)[self.name length]);
}

- (BOOL)existsTable
{
    return self.handler && self.indexTable.handler ? YES : NO;
}

- (BOOL)includeWithLocation:(CLLocationCoordinate2D)currentLocation targetLocation:(CLLocationCoordinate2D)targetLocation withRadius:(CGFloat)radius
{
    grn_obj *center = [self openWgs84GeoPointWithLatitude:currentLocation.latitude withLongitude:currentLocation.longitude];
    grn_obj *target = [self openWgs84GeoPointWithLatitude:targetLocation.latitude withLongitude:targetLocation.longitude];
    grn_obj radiusObj;
    GRN_UINT32_INIT(&radiusObj, 0);
    GRN_UINT32_PUT(self.ctx, &radiusObj, radius);
    BOOL ret = grn_geo_in_circle(self.ctx, target, center, &radiusObj, GRN_GEO_APPROXIMATE_SPHERE);
    grn_obj_close(self.ctx, &radiusObj);
    grn_obj_close(self.ctx, target);
    grn_obj_close(self.ctx, center);
    return ret;
}

- (void)createLocationIndexColumnWithName:(NSString *)columnName withTargetColumnName:(NSString *)targetColumnName;
{
    NSString *indexTableName    = @"Locations";
    IroongaLocationTable *table = [IroongaLocationTable createTableWithCTX:self.ctx withName:indexTableName withTableType:IroongaTableTypePat withTableKeyType:IroongaTableKeyTypeWGS84GeoPoint];
    [table addIndexColumnWithTableName:self.name withColumnName:columnName withTargetColumnName:targetColumnName];
    NSString *index = [NSString stringWithFormat:@"%@.%@", indexTableName, columnName];
    table.handler    = grn_ctx_get(self.ctx, [index UTF8String], (int)[index length]);
    self.indexTable = table;
}

- (void)loadLocationIndexTableWithName:(NSString *)name withColumnName:(NSString *)columnName
{
    NSString *indexTableName = @"Locations";
    NSString *index          = [NSString stringWithFormat:@"%@.%@", indexTableName, columnName];
    self.indexTable          = [[IroongaLocationTable alloc] initWithCTX:self.ctx withName:indexTableName];
    self.indexTable.handler  = grn_ctx_get(self.ctx, [index UTF8String], (int)[index length]);
}

- (void)addIndexColumnWithTableName:(NSString *)tableName withColumnName:(NSString *)columnName withTargetColumnName:(NSString *)targetColumnName
{
    grn_obj *command  = grn_ctx_get(self.ctx, "column_create", strlen("column_create"));
    grn_obj *tableObj = grn_expr_get_var(self.ctx, command, "table", strlen("table"));
    grn_obj *nameObj  = grn_expr_get_var(self.ctx, command, "name", strlen("name"));
    grn_obj *flagsObj = grn_expr_get_var(self.ctx, command, "flags", strlen("flags"));
    grn_obj *typeObj  = grn_expr_get_var(self.ctx, command, "type", strlen("type"));
    grn_obj *srcObj   = grn_expr_get_var(self.ctx, command, "source", strlen("source"));
    GRN_TEXT_PUTS(self.ctx, tableObj, [self.name UTF8String]);
    GRN_TEXT_PUTS(self.ctx, nameObj,  [columnName UTF8String]);
    GRN_TEXT_PUTS(self.ctx, flagsObj, [[self columnTypeToString:IroongaColumnTypeIndex] UTF8String]);
    GRN_TEXT_PUTS(self.ctx, typeObj,  [tableName UTF8String]);
    GRN_TEXT_PUTS(self.ctx, srcObj,   [targetColumnName UTF8String]);
    grn_expr_exec(self.ctx, command, 0);
    
    DEBUG_LOG(@"column_create %@ %@ %@ %@ %@", self.name, columnName, [self columnTypeToString:IroongaColumnTypeIndex], tableName, targetColumnName);
}

- (void)createColumnWithName:(NSString *)columnName withColumnType:(IroongaColumnType)columnType type:(IroongaTableKeyType)keyType source:(NSString *)source
{
    self.columnData[columnName] = @(columnType);
    grn_obj *command  = grn_ctx_get(self.ctx, "column_create", strlen("column_create"));
    grn_obj *tableObj = grn_expr_get_var(self.ctx, command, "table", strlen("table"));
    grn_obj *nameObj  = grn_expr_get_var(self.ctx, command, "name", strlen("name"));
    grn_obj *flagsObj = grn_expr_get_var(self.ctx, command, "flags", strlen("flags"));
    grn_obj *typeObj  = grn_expr_get_var(self.ctx, command, "type", strlen("type"));
    grn_obj *srcObj   = grn_expr_get_var(self.ctx, command, "source", strlen("source"));
    GRN_TEXT_PUTS(self.ctx, tableObj, [self.name UTF8String]);
    GRN_TEXT_PUTS(self.ctx, nameObj,  [columnName UTF8String]);
    GRN_TEXT_PUTS(self.ctx, flagsObj, [[self columnTypeToString:columnType] UTF8String]);
    GRN_TEXT_PUTS(self.ctx, typeObj,  [[self tableKeyTypeToString:keyType] UTF8String]);
    GRN_TEXT_PUTS(self.ctx, srcObj,  [source UTF8String]);
    grn_expr_exec(self.ctx, command, 0);
    
    DEBUG_LOG(@"column_create %@ %@ %@ %@ %@", self.name, columnName, [self columnTypeToString:columnType], [self tableKeyTypeToString:keyType], source);
}

- (void)loadDataFromJSONFile:(NSString *)filePath
{
    NSString *data = [[NSString alloc] initWithData:[NSData dataWithContentsOfFile:filePath] encoding:NSUTF8StringEncoding];
    grn_obj *command = grn_ctx_get(self.ctx, "load", strlen("load"));
    grn_obj *values = grn_expr_get_var(self.ctx, command, "values", strlen("values"));
    grn_obj_reinit(self.ctx, values, GRN_DB_TEXT, 0);
    GRN_TEXT_PUTS(self.ctx, values, [data UTF8String]);
    
    grn_obj *table = grn_expr_get_var(self.ctx, command, "table", strlen("table"));
    grn_obj_reinit(self.ctx, table, GRN_DB_TEXT, 0);
    GRN_TEXT_PUTS(self.ctx, table, [self.name UTF8String]);
    
    grn_expr_exec(self.ctx, command, 0);
    
    grn_ctx_info info;
    grn_ctx_info_get(self.ctx, &info);
    DEBUG_LOG(@"%d, %s\n", (int)GRN_TEXT_LEN(info.outbuf), GRN_TEXT_VALUE(info.outbuf));
    [self loadHandler];
}

- (NSMutableArray *)selectWithQuery:(NSString *)query
{
    grn_obj *expression, *variable;
    GRN_EXPR_CREATE_FOR_QUERY(self.ctx, self.handler, expression, variable);
    grn_expr_parse(self.ctx, expression,
                   [query UTF8String], (int)[query length],
                   NULL, GRN_OP_MATCH, GRN_OP_OR,
                   GRN_EXPR_SYNTAX_QUERY | GRN_EXPR_ALLOW_COLUMN);
    grn_obj *resultTable = grn_table_select(self.ctx, self.handler, expression, NULL, GRN_OP_OR);
    NSMutableArray *ret = [self parseResultTable:resultTable];
    grn_obj_close(self.ctx, resultTable);
    return ret;
}

- (NSMutableArray *)parseResultTable:(grn_obj *)resultTable
{
    grn_table_cursor *cursor = grn_table_cursor_open(self.ctx, resultTable,
                                                     NULL, 0,
                                                     NULL, 0,
                                                     0, -1,
                                                     GRN_CURSOR_ASCENDING | GRN_CURSOR_BY_ID);
    grn_id recordId = grn_table_cursor_next(self.ctx, cursor);
    NSMutableArray *rows = [@[] mutableCopy];
    while (recordId) {
        NSMutableDictionary *row = [@{} mutableCopy];
        IroongaRecordArgument *arg = [[IroongaRecordArgument alloc] init];
        arg.recordId               = recordId;
        arg.columnName             = @"_id";
        arg.table                  = resultTable;
        row[@"objectId"]           = [self getUInt32FromId:arg];
        for (NSString *columnName in [self.columnData allKeys]) {
            IroongaTableKeyType type = [self.columnData[columnName] intValue];
            NSString *typeName       = [self tableKeyTypeToString:type];
            SEL sel                  = NSSelectorFromString([NSString stringWithFormat:@"get%@FromId:", typeName]);
            IroongaRecordArgument *arg = [[IroongaRecordArgument alloc] init];
            arg.recordId               = recordId;
            arg.table                  = resultTable;
            arg.columnName             = columnName;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            row[columnName]          = [self performSelector:sel withObject:arg];
#pragma clang diagnostic pop
        }
        [rows addObject:row];
        recordId = grn_table_cursor_next(self.ctx, cursor);
    }
    grn_obj_close(self.ctx, cursor);
    return rows;
}

- (NSMutableArray *)findWithTopLeftPoint:(CLLocationCoordinate2D)topLeftPoint withBottomRightPoint:(CLLocationCoordinate2D)bottomRightPoint
{
    grn_obj *resultTable = grn_table_create(self.ctx,
                                            NULL, 0,
                                            NULL,
                                            GRN_TABLE_HASH_KEY | GRN_OBJ_WITH_SUBREC,
                                            self.handler, NULL);
    
    grn_obj *topLeft      = [self openWgs84GeoPointWithLatitude:topLeftPoint.latitude withLongitude:topLeftPoint.longitude];
    grn_obj *bottomRight  = [self openWgs84GeoPointWithLatitude:bottomRightPoint.latitude withLongitude:bottomRightPoint.longitude];
    
    grn_geo_select_in_rectangle(self.ctx, self.indexTable.handler, topLeft, bottomRight, resultTable, GRN_OP_OR);
    NSMutableArray *ret = [self parseResultTable:resultTable];
    
    grn_obj_close(self.ctx, resultTable);
    grn_obj_close(self.ctx, topLeft);
    grn_obj_close(self.ctx, bottomRight);
    
    return ret;
}

- (NSNumber *)getUInt32FromId:(IroongaRecordArgument *)arg
{
    grn_obj value;
    GRN_UINT32_INIT(&value, 0);
    grn_obj *column = grn_obj_column(self.ctx, arg.table, [arg.columnName UTF8String], (int)[arg.columnName length]);
    grn_obj_get_value(self.ctx, column, arg.recordId, &value);
    NSUInteger ret = GRN_UINT32_VALUE(&value);
    grn_obj_close(self.ctx, &value);
    grn_obj_close(self.ctx, column);
    return @(ret);
}

- (NSNumber *)getFloatFromId:(IroongaRecordArgument *)arg
{
    grn_obj value;
    GRN_FLOAT_INIT(&value, 0);
    grn_obj *column = grn_obj_column(self.ctx, arg.table, [arg.columnName UTF8String], (int)[arg.columnName length]);
    grn_obj_get_value(self.ctx, column, arg.recordId, &value);
    CGFloat ret = GRN_FLOAT_VALUE(&value);
    grn_obj_close(self.ctx, &value);
    grn_obj_close(self.ctx, column);
    return @(ret);
}

- (NSString *)getTextFromId:(IroongaRecordArgument *)arg
{
    grn_obj value;
    GRN_TEXT_INIT(&value, 0);
    grn_obj *column = grn_obj_column(self.ctx, arg.table, [arg.columnName UTF8String], (int)[arg.columnName length]);
    grn_obj_get_value(self.ctx, column, arg.recordId, &value);
    char *text = GRN_TEXT_VALUE(&value);
    grn_obj_close(self.ctx, &value);
    grn_obj_close(self.ctx, column);
    return (text && @(text)) ? @(text) : @"";
}

- (CLLocation *)getWGS84GeoPointFromId:(IroongaRecordArgument *)arg
{
    grn_obj value;
    GRN_WGS84_GEO_POINT_INIT(&value, 0);
    grn_obj *column = grn_obj_column(self.ctx, arg.table, [arg.columnName UTF8String], (int)[arg.columnName length]);
    grn_obj_get_value(self.ctx, column, arg.recordId, &value);
    float latitude  = 0;
    float longitude = 0;
    GRN_GEO_POINT_VALUE(&value, latitude, longitude);
    grn_obj_close(self.ctx, &value);
    grn_obj_close(self.ctx, column);
    return [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
}

- (grn_obj *)openGeoPointWithLatitude:(double)latitude withLongitude:(double)longitude
{
    grn_obj *point = grn_obj_open(self.ctx, GRN_BULK, 0, GRN_DB_SHORT_TEXT);
    const char *str = [[NSString stringWithFormat:@"%f,%f", latitude, longitude] UTF8String];
    GRN_TEXT_PUTS(self.ctx, point, str);
    return point;
}

- (grn_obj *)openWgs84GeoPointWithLatitude:(double)latitude withLongitude:(double)longitude
{
    grn_obj *pointText = [self openGeoPointWithLatitude:latitude withLongitude:longitude];
    grn_obj *point = grn_obj_open(self.ctx, GRN_BULK, 0, GRN_DB_WGS84_GEO_POINT);
    grn_obj_cast(self.ctx, pointText, point, GRN_FALSE);
    grn_obj_unlink(self.ctx, pointText);
    return point;
}

#undef DEBUG_LOG

@end
