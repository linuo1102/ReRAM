/*
 * HHTable.h
 * Hierarchical Hash Table for the Endurance counters
 * 
 * Created by Miguel Lastras on Feb 24, 2015
 */

#import <Foundation/Foundation.h>

@interface HHTable : NSObject {
  NSString *name;
  unsigned long int s1Offset;
  unsigned long int s2Offset;
  unsigned long int s3Offset; 
  unsigned long int s4Offset; 
  unsigned long int s1BlockSize;
  unsigned long int s2BlockSize;
  unsigned long int s3BlockSize;
  unsigned long int s4BlockSize;
  unsigned long int s1Mask;
  unsigned long int s2Mask;
  unsigned long int s3Mask;
  unsigned long int s4Mask;
  unsigned long int L1_index;
  unsigned long int L2_index;
  unsigned long int L3_index;
  unsigned long int L4_index;
  unsigned long int ****hashTable;
  unsigned long int *eCountByPage;
  unsigned long int *eCountByByte;
  unsigned long int pages;
  unsigned long int bytes;
}

@property (nonatomic, readonly) unsigned long int pages;
@property (nonatomic, readonly) unsigned long int bytes;

/*
@property (nonatomic, readonly) unsigned long int s1Offset;
@property (nonatomic, readonly) unsigned long int s2Offset;
@property (nonatomic, readonly) unsigned long int s3Offset;
@property (nonatomic, readonly) unsigned long int s4Offset;
@property (nonatomic, readonly) unsigned long int s1BlockSize;
@property (nonatomic, readonly) unsigned long int s2BlockSize;
@property (nonatomic, readonly) unsigned long int s3BlockSize;
@property (nonatomic, readonly) unsigned long int s4BlockSize;
@property (nonatomic, readonly) unsigned long int s1Mask;
@property (nonatomic, readonly) unsigned long int s2Mask;
@property (nonatomic, readonly) unsigned long int s3Mask;
@property (nonatomic, readonly) unsigned long int s4Mask;
@property (nonatomic) unsigned long int ****hashTable;
*/

- (id) initWithB4:(unsigned long int)b4
               b3:(unsigned long int)b3
               b2:(unsigned long int)b2
               b1:(unsigned long int)b1;
- (void) allocateSelectAddress:(unsigned long int)address;
- (void) releaseMemory;
- (unsigned long int) numberOfPages;
- (unsigned long int) numberOfBytes;

// Endurance related operations
- (void) increasePageEnduranceBy:(unsigned long int)amount;
- (void) increaseByteEnduranceBy:(unsigned  long int)amount;
- (void) increaseBlockEnduranceOfSize:(unsigned long int)size
                           withAmount:(unsigned long int)amount;
- (void) resetEndurance;
- (unsigned long int) computeTotalEnduranceWithReset:(BOOL)reset;
- (unsigned long int*) computeEnduranceByPage;
- (unsigned long int*) computeEnduranceByByte;

- (unsigned long int****) initLevel4;
- (unsigned long int***)  initLevel3;
- (unsigned long int**)   initLevel2;
- (unsigned long int*)    initLevel1;

@end

