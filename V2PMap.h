/*
 * V2PMap.h
 * Virtual to Physical Mapping
 *
 * Created by Miguel Lastras on April 29, 2015
 */

#import <Foundation/Foundation.h>
#import "GlobalDefinitions.h"
#import "HPTable.h"

@interface V2PMap : NSObject {
  FILE *pagemap;
  HPTable *hashTable;
  unsigned long int foundCounter;
  unsigned long int notFoundCounter;
  unsigned long int swappedCounter;
}

@property (nonatomic, readonly) unsigned long int foundCounter;
@property (nonatomic, readonly) unsigned long int notFoundCounter;
@property (nonatomic, readonly) unsigned long int swappedCounter;

- (id) initWithFileName:(NSString*)fileName;
- (unsigned long int) getPhysicalAddressFrom:(unsigned long int)address;
- (void) releaseMemory;

@end
