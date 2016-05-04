/*
 * SACacheX.h
 * Set Associative Cache with Extended Functionality
 *
 * Created by Miguel Lastras on Apr 20, 2015
 */

#import <Foundation/Foundation.h>
#import "GlobalDefinitions.h"
#import "InterfaceProtocol.h"

#define VALID 1UL
#define DIRTY 2UL
#define MEMRISTIVE_MODE 4UL
// add other flags here

struct CacheEntry
{
  unsigned long int tag;
  unsigned long int recentAccessCount;
  unsigned long int timeStamp;
  unsigned long int flags;
  unsigned long int *toggleByteCount;
};

@interface SACacheX : NSObject <InterfaceProtocol> {
  NSString *name;
  unsigned long int sets;
  unsigned long int associativity;
  unsigned long int blockSize;
  unsigned long int capacityInBytes;
  unsigned long int setsBits;
  unsigned long int associativityBits;
  unsigned long int blockSizeBits;
  unsigned long int indexOffset;
  unsigned long int indexMask;
  unsigned long int offsetMask;
  unsigned long int blockAddressMask;
  unsigned long int tagOffset;
  unsigned long int accessCount;
  unsigned long int hits;
  unsigned long int misses;
  unsigned long int mHits;
  unsigned long int mMisses;
  unsigned long int readPenalty;
  unsigned long int writePenalty;
  unsigned long int loadFromCRSPenalty;
  unsigned long int loadFromMemristorPenalty;
  unsigned long int deactivationPenalty;
  unsigned long int pages;
  unsigned long int bytes;
  BOOL hybridEnabled;
  BOOL crsOnlyEnabled;
  struct CacheEntry **memoryArray;
  unsigned long int *tCountByPage;
  unsigned long int *tCountByByte;
  char memoryCapacity[32];
  id next;
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) unsigned long int sets;
@property (nonatomic, readonly) unsigned long int setsBits;
@property (nonatomic, readonly) unsigned long int associativity;
@property (nonatomic, readonly) unsigned long int associativityBits;
@property (nonatomic, readonly) unsigned long int blockSize;
@property (nonatomic, readonly) unsigned long int blockSizeBits;
@property (nonatomic, readonly) unsigned long int indexOffset;
@property (nonatomic, readonly) unsigned long int indexMask;
@property (nonatomic, readonly) unsigned long int offsetMask;
@property (nonatomic, readonly) unsigned long int blockAddressMask;
@property (nonatomic, readonly) unsigned long int tagOffset;
@property (nonatomic) unsigned long int accessCount;
@property (nonatomic) unsigned long int hits;
@property (nonatomic) unsigned long int misses;
@property (nonatomic) unsigned long int mHits;
@property (nonatomic) unsigned long int mMisses;
@property (nonatomic) struct CacheEntry **memoryArray;

@property (nonatomic, readonly) unsigned long int pages;
@property (nonatomic, readonly) unsigned long int bytes;

// Public interface (any cache/memory should have it)
- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read;

// Public interface but specific for this cache
- (id) initWithSetsBits:(unsigned long int)sb
      associativityBits:(unsigned long int)ab
      bytesPerBlockBits:(unsigned long int)bb
              nextLevel:(id)theNext
                   name:(NSString*)theName
                CRSOnly:(BOOL)crsOnly
                 hybrid:(BOOL)hybrid;
- (id) initWithSets:(unsigned long int)s 
      associativity:(unsigned long int)a
      bytesPerBlock:(unsigned long int)b
          nextLevel:(id)theNext
               name:(NSString*)theName
            CRSOnly:(BOOL)crsOnly
             hybrid:(BOOL)hybrid;
- (void) releaseMemory;
- (void) printCapacity;

// Private interface /////////////////

/* Description:
 Returns YES if the tag is present in the set and
 the entry is valid. Returns NO otherwise. */
- (BOOL) lookupTag:(unsigned long int)tag
             onSet:(struct CacheEntry*)set;

/* Description:
 Returns YES if the position tag is assgined in the set
 is in memristive mode. Returns NO otherwise.
 Note that tag MUST be present in the set. */
- (BOOL) checkModeOnTag:(unsigned long int)tag
                  onSet:(struct CacheEntry*)set;

/* Description:
 Returns ULONG_MAX if the insertion did not produce
 an eviction, i.e., there was a position available
 in the set either because a position was 'invalid' or
 because a valid position was 'not dirty'. Otherwise it
 returns the 'tag' of the evicted block. The eviction is
 selected based on the timeStamp of the tag. Note that
 ULONG_MAX is not a valid value for a tag.
 In both cases after the tag is succesfully inserted,
 its 'valid' bit is asserted and its timeStamp is updated
 Note that its 'dirty' bit is left untouched. It should
 be handled outside this function. */
- (unsigned long int) insertTag:(unsigned long int)tag
                          onSet:(struct CacheEntry*)set;

/* Description:
 Update the toggle count on the given tag, set and
 starting on the given offset. It does so for the as
 many as 'size' bytes. The tag must be present, if not, 
 an assertion will break the program. Also the access must
 be aligned to the blockSize, if not, an assertion will 
 break the program. This method updates the timeStamp of 
 the given tag in the given set.
 Finally, the method takes into account the toggle needed
 to change something from CRS to memristive mode if needed.*/
- (void) updateToggleOnTag:(unsigned long int)tag
                     onSet:(struct CacheEntry*)set
                withOffset:(unsigned long int)offset
                    ofSize:(unsigned long int)size
                withAmount:(unsigned long int)amount;

/* Description:
 Same as updateToggleOnTag, but updates the toggle counter
 in all the page and it does so by considering if a page is
 in memristive mode or CRS mode. */
- (void) updatePageToggleOnTag:(unsigned long int)tag
                         onSet:(struct CacheEntry*)set;

/* Description:
 Marks the given tag on the given set as given in 'dirty'. 
 The tag must be present, if not, an assertion will break
 the program. */
- (void) markTag:(unsigned long int)tag
           onSet:(struct CacheEntry*)set
         asDirty:(BOOL)dirty;

/* Description:
 Deactivate unused blocks to decrease the memristive fraction.  */
- (void) deactivateUnsedBlocks;

// Functions to increase and decrease the access counters
- (void) increaseAccessCounterOn:(unsigned long int*)address;
- (void) decreaseAccessCounterOn:(unsigned long int*)address;

// Other methods
- (void) printConfiguration;
- (double) activeFraction;
- (double) memristiveFraction;
- (unsigned long int*) computeToggleByPage;
- (unsigned long int*) computeToggleByByte;
- (void) resetEndurance;
- (NSString*) memoryCapacity;

@end
