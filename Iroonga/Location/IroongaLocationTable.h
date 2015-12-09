//
//  IroongaLocationTable.h
//  Created by goccy on 2015/09/06.
//  Copyright (c) 2015年 goccy. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <groonga.h>
#include <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSUInteger, IroongaTableType) {
    IroongaTableTypeHash,
    IroongaTableTypePat,
    IroongaTableTypeDat,
    IroongaTableTypeNo,
};

typedef NS_ENUM(NSUInteger, IroongaTableKeyType) {
    IroongaTableKeyTypeObject,
    IroongaTableKeyTypeBool,
    IroongaTableKeyTypeInt8,
    IroongaTableKeyTypeUInt8,
    IroongaTableKeyTypeInt16,
    IroongaTableKeyTypeUInt16,
    IroongaTableKeyTypeInt32,
    IroongaTableKeyTypeUInt32,
    IroongaTableKeyTypeInt64,
    IroongaTableKeyTypeUInt64,
    IroongaTableKeyTypeFloat,
    IroongaTableKeyTypeTime,
    IroongaTableKeyTypeShortText,
    IroongaTableKeyTypeText,
    IroongaTableKeyTypeLongText,
    IroongaTableKeyTypeTokyoGeoPoint,
    IroongaTableKeyTypeWGS84GeoPoint,
};

typedef NS_ENUM(NSUInteger, IroongaColumnType) {
    IroongaColumnTypeScalar       = 1,
    IroongaColumnTypeVector       = 1 << 0,
    IroongaColumnTypeIndex        = 1 << 1,
    IroongaColumnTypeCompressZlib = 1 << 4,
    IroongaColumnTypeCompressLZO  = 1 << 5,
    IroongaColumnTypeWithSection  = 1 << 7,
    IroongaColumnTypeWithWeight   = 1 << 8,
    IroongaColumnTypeWithPosition = 1 << 9,
};

@interface IroongaLocationTable : NSObject

@property(nonatomic) NSString *name;

- (instancetype)initWithCTX:(grn_ctx *)ctx withName:(NSString *)name;
+ (instancetype)createTableWithCTX:(grn_ctx *)ctx withName:(NSString *)name withTableType:(IroongaTableType)tableType withTableKeyType:(IroongaTableKeyType)tableKeyType;
- (void)createColumnWithName:(NSString *)columnName withColumnType:(IroongaColumnType)columnType type:(IroongaTableKeyType)keyType source:(NSString *)source;
- (void)createLocationIndexColumnWithName:(NSString *)columnName withTargetColumnName:(NSString *)targetColumnName;
- (void)loadLocationIndexTableWithName:(NSString *)name withColumnName:(NSString *)columnName;
- (void)loadDataFromJSONFile:(NSString *)filePath;
- (void)loadHandler;
- (NSArray *)selectWithQuery:(NSString *)query;
- (NSMutableArray *)findWithTopLeftPoint:(CLLocationCoordinate2D)topLeftPoint withBottomRightPoint:(CLLocationCoordinate2D)bottomRightPoint;
- (BOOL)existsTable;
- (BOOL)includeWithLocation:(CLLocationCoordinate2D)currentLocation targetLocation:(CLLocationCoordinate2D)targetLocation withRadius:(CGFloat)radius;

@end
