/*
 * HPTable.h
 * Hierarchical Page Hash Table
 * 
 * Created by Miguel Lastras on May 1, 2015
 */

#import <Foundation/Foundation.h>
#import "GlobalFunctions.h"
#import "GlobalDefinitions.h"

@interface HPTable : NSObject {
  NSString *name;
  unsigned long int s1Offset;
  unsigned long int s2Offset;
  unsigned long int s3Offset;
  unsigned long int s1BlockSize;
  unsigned long int s2BlockSize;
  unsigned long int s3BlockSize;
  unsigned long int s1Mask;
  unsigned long int s2Mask;
  unsigned long int s3Mask;
  unsigned long int L1_index;
  unsigned long int L2_index;
  unsigned long int L3_index;
  unsigned long int ***hashTable;
  unsigned long int pages;
}

- (id) initWithB3:(unsigned long int)b3
               b2:(unsigned long int)b2
               b1:(unsigned long int)b1;
- (void) releaseMemory;
- (unsigned long int) numberOfPages;

/* Writes particular address to 0. Note that key pointed by address
 must be present and valid. Otherwise an assertion will break 
 the program. */
- (void) invalidateKeyOnAddress:(unsigned long int)address;

- (void) invalidateAllEntries; // writes them to 0

/* insertKey needs 'getKeyOnAddress' to be called first to
 select-allocate the right position */
- (void) insertKey:(unsigned long int)key;
- (unsigned long int) getKeyOnAddress:(unsigned long int)address;

- (unsigned long int***) initLevel3;
- (unsigned long int**)  initLevel2;
- (unsigned long int*)   initLevel1;

@end

