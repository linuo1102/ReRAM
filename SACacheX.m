/*
 * SACacheX.m
 * Set Associative Cache with Extended Functionality
 *
 * Created by Miguel Lastras on Apr 20, 2015
 */

#import "SACacheX.h"
#import "GlobalFunctions.h"

@implementation SACacheX

@synthesize name;
@synthesize sets;
@synthesize setsBits;
@synthesize associativity;
@synthesize associativityBits;
@synthesize blockSize;
@synthesize blockSizeBits;
@synthesize indexOffset;
@synthesize indexMask;
@synthesize offsetMask;
@synthesize blockAddressMask;
@synthesize tagOffset;
@synthesize accessCount;
@synthesize hits;
@synthesize misses;
@synthesize mHits;
@synthesize mMisses;
@synthesize memoryArray;
@synthesize pages;
@synthesize bytes;



// TODO: ADD THE Conflict MISSES, THEY WILL TELL YOU IF YOU ARE MAKING THE WRONG ASSUMPTION

///////////////////////////////////////
// PUBLIC INTERFACE ///////////////////
- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read
{
  accessCount++;
  unsigned long int blockAddress = address & blockAddressMask;
  unsigned long int offset = address & offsetMask;
  unsigned long int index = (address & indexMask) >> indexOffset;
  unsigned long int tag = address >> tagOffset;
  
  if( [self lookupTag:tag onSet:memoryArray[index]] ){
    hits++;
    
    // udpate memristive hit counters (on cache hit)
    if( [self checkModeOnTag:tag onSet:memoryArray[index]] ) // block is in memristive mode
      mHits++;
    else // block is in CRS mode
      mMisses++;
    
    if( read )
      [self updateToggleOnTag:tag onSet:memoryArray[index] withOffset:offset ofSize:size withAmount:readPenalty];
    else{ // ( write )
      [self updateToggleOnTag:tag onSet:memoryArray[index] withOffset:offset ofSize:size withAmount:writePenalty];
      [self markTag:tag onSet:memoryArray[index] asDirty:YES];
    }
  }
  else{
    misses++;
    [next accessBlock:blockAddress ofSize:blockSize readOperation:YES]; // bring the whole block from the next level
    unsigned long int evictedTag = [self insertTag:tag onSet:memoryArray[index]]; // insert it
    
    // udpate memristive hit counters (on cache miss)
    if( [self checkModeOnTag:tag onSet:memoryArray[index]] ) // block is in memristive mode
      mHits++;
    else // block is in CRS mode
      mMisses++;
    
    [self updatePageToggleOnTag:tag onSet:memoryArray[index]]; // increase toggle in the whole page due to the load
    
    // handle the possible eviction
    if( evictedTag != ULONG_MAX ){
      unsigned long int evictedBlockAddress = evictedTag << tagOffset | (index << indexOffset);
      [next accessBlock:evictedBlockAddress ofSize:blockSize readOperation:NO]; // write back the eviction
    }
    
    if( read ){
      [self updateToggleOnTag:tag onSet:memoryArray[index] withOffset:offset ofSize:size withAmount:readPenalty];
      [self markTag:tag onSet:memoryArray[index] asDirty:NO];
    }
    else{
      [self updateToggleOnTag:tag onSet:memoryArray[index] withOffset:offset ofSize:size withAmount:writePenalty];
      [self markTag:tag onSet:memoryArray[index] asDirty:YES];
    }
  }
}
// PUBLIC INTERFACE ///////////////////
///////////////////////////////////////

- (id) initWithSetsBits:(unsigned long int)sb
      associativityBits:(unsigned long int)ab
      bytesPerBlockBits:(unsigned long int)bb
              nextLevel:(id)theNext
                   name:(NSString*)theName
                CRSOnly:(BOOL)crsOnly
                 hybrid:(BOOL)hybrid
{
  assert( !(crsOnly && hybrid) ); // cannot be crsOnly and hybrid at the same time
  setsBits = sb;
  associativityBits = ab;
  blockSizeBits = bb;
  unsigned long int s = 1UL << sb;
  unsigned long int a = 1UL << ab;
  unsigned long int b = 1UL << bb;
  return [self initWithSets:s associativity:a bytesPerBlock:b nextLevel:theNext name:theName CRSOnly:crsOnly hybrid:hybrid];
}

- (id) initWithSets:(unsigned long int)s
      associativity:(unsigned long int)a 
      bytesPerBlock:(unsigned long int)b
          nextLevel:(id)theNext
               name:(NSString*)theName
            CRSOnly:(BOOL)crsOnly
             hybrid:(BOOL)hybrid
{
  self = [super init];
  if(self != nil){
    assert( !(crsOnly && hybrid) ); // cannot be crsOnly and hybrid at the same time
    name = theName;
    sets = s;
    associativity = a;
    blockSize = b;
    capacityInBytes = s*a*b;
    bytes = s*a*b;
    pages = s*a;
    setsBits = [GlobalFunctions log2floor:s];
    associativityBits = [GlobalFunctions log2floor:a];
    blockSizeBits = [GlobalFunctions log2floor:b];
    indexOffset = blockSizeBits;
    indexMask = (sets - 1UL) << blockSizeBits;
    offsetMask = blockSize - 1UL;
    blockAddressMask = ~offsetMask;
    tagOffset = blockSizeBits + setsBits;
    accessCount = 0;
    hits = 0;
    misses = 0;
    mHits = 0;
    mMisses = 0;
    next = theNext;
    hybridEnabled = hybrid;
    crsOnlyEnabled = crsOnly;

    if( crsOnly ){
      readPenalty = SINGLE;
      writePenalty = DELTA/2;
      loadFromCRSPenalty = DELTA/2;
      loadFromMemristorPenalty = DELTA/2; // this case shouldn't use this penalty
      deactivationPenalty = 0; // shouldn't be used
    } else if( hybrid ){
      readPenalty = 0;
      writePenalty = SINGLE/2;
      loadFromCRSPenalty = (DELTA+SINGLE)/2;
      loadFromMemristorPenalty = SINGLE/2;
      deactivationPenalty = (DELTA+SINGLE)/2;
    } else{
      readPenalty = 0;
      writePenalty = SINGLE/2;
      loadFromCRSPenalty = SINGLE/2; // this case shouldn't use this penalty
      loadFromMemristorPenalty = SINGLE/2;
      deactivationPenalty = 0; // shouldn't be used
    }
    
    // allocate memory for the memory array
    memoryArray = (struct CacheEntry**) malloc(sets * sizeof(struct CacheEntry*));
    for( int i=0; i<sets; i++ ){
      memoryArray[i] = (struct CacheEntry*) malloc(associativity * sizeof(struct CacheEntry));
      for( int j=0; j<associativity; j++ ){
        memoryArray[i][j].toggleByteCount = (unsigned long int*) malloc( blockSize * sizeof(unsigned long int) );
      }
    }
      
    // Initialize and invalidate all entries
    for( int i=0; i<sets; i++ ){
      for( int j=0; j<associativity; j++ ){
        memoryArray[i][j].recentAccessCount = 0; // New memory :)
        memoryArray[i][j].timeStamp = 0; // The beginning of time :)
        memoryArray[i][j].tag = 0; // the 'tag' field shouldn't (in principle) be initialized
        if( crsOnly )
          memoryArray[i][j].flags = 0;
        else if( hybrid )
          memoryArray[i][j].flags = 0; // MEMRISTIVE_MODE or 0
        else
          memoryArray[i][j].flags = MEMRISTIVE_MODE;
        for( int k=0; k<blockSize; k++ ){
          memoryArray[i][j].toggleByteCount[k] = 0; // New memory :)
        }
      }
    }
  } // if(self != nil)
  return self;
}

- (void) releaseMemory
{
  for( int i=0; i<sets; i++ ){
    for( int j=0; j<associativity; j++ ){
      assert( memoryArray[i][j].toggleByteCount != NULL );
      free(memoryArray[i][j].toggleByteCount);
    }
    assert( memoryArray[i] != NULL );
    free(memoryArray[i]);
  }
  assert(memoryArray != NULL);
  free(memoryArray);
  
  if(tCountByPage != NULL)
    free(tCountByPage);
  if(tCountByByte != NULL)
    free(tCountByByte);
  
}

- (BOOL) lookupTag:(unsigned long int)tag
             onSet:(struct CacheEntry*)set
{
  for( int i=0; i<associativity; i++ )
    if( (set[i].tag == tag) && ( set[i].flags & VALID ) )
      return YES;
  return NO;
}

- (BOOL) checkModeOnTag:(unsigned long int)tag
                  onSet:(struct CacheEntry*)set
{
  for( int i=0; i<associativity; i++ )
    if( (set[i].tag == tag) && ( set[i].flags & MEMRISTIVE_MODE ) )
      return YES;
  return NO;
}

- (unsigned long int) insertTag:(unsigned long int)tag
                          onSet:(struct CacheEntry*)set
{
  // Look for a position based on the 'valid' bit
  int pos;
  for( pos=0; pos<associativity; pos++ )
    if( !(set[pos].flags & VALID) )
      break;
  if( pos < associativity ){ // there is a position available
    set[pos].tag = tag; // insert it...
    set[pos].timeStamp = GlobalTime; // update the time stamp
    [self increaseAccessCounterOn:&set[pos].recentAccessCount];
    set[pos].flags |= VALID; // make it valid
    return ULONG_MAX; // (no eviction was necessary)
    // Since 'ULONG_MAX' is an invalid address, we use it to
    // notify that no eviction was needed.
  }
  
  // If we made it up to here, there was no 'invalid' position
  // so we find one based on the timeStamp (we look for the entry
  // with the smallest/youngest timeStamp).
  pos = 0;
  unsigned long int time = ULONG_MAX; // the end of time
  for( int i=0; i<associativity; i++ ){
    if( set[i].timeStamp < time ){
      time = set[i].timeStamp;
      pos = i;
    }
  }
  
  // If the selected position was dirty:
  if( set[pos].flags & DIRTY ){
    unsigned long int evicted = set[pos].tag; // extract the youngest
    set[pos].tag = tag; // insert tag in the position of the youngest
    set[pos].timeStamp = GlobalTime; // update the time stamp
    [self increaseAccessCounterOn:&set[pos].recentAccessCount];
    set[pos].flags |= VALID; // make it valid (not strictly needed)
    return evicted; // return the evicted
  }
  // If it was not dirty:
  set[pos].tag = tag; // insert tag in the position of the youngest
  set[pos].timeStamp = GlobalTime; // update the time stamp
  [self increaseAccessCounterOn:&set[pos].recentAccessCount];
  set[pos].flags |= VALID; // make it valid (not strictly needed)
  return ULONG_MAX; // (no eviction was necessary)
}

- (void) updateToggleOnTag:(unsigned long int)tag
                     onSet:(struct CacheEntry*)set
                withOffset:(unsigned long int)offset
                    ofSize:(unsigned long int)size
                withAmount:(unsigned long int)amount
{
  int pos;
  for( pos=0; pos<associativity; pos++ )
    if( (set[pos].tag == tag) && ( set[pos].flags & VALID ) )
      break;
  assert( pos != associativity ); // tag must be in the set
  assert( (offset+size) <= blockSize ); // Accesses must be aligned!
  set[pos].timeStamp = GlobalTime; // update timeStamp
  [self increaseAccessCounterOn:&set[pos].recentAccessCount];
  
  if( hybridEnabled && !(set[pos].flags & MEMRISTIVE_MODE) ) // if page is in CRS and hybrid is enabled
    [self updatePageToggleOnTag:tag onSet:set]; // Activate page
  
  for( int i=0; i<size; i++ )
    set[pos].toggleByteCount[i+offset] += amount;
}

- (void) updatePageToggleOnTag:(unsigned long int)tag
                         onSet:(struct CacheEntry*)set
{
  int pos;
  for( pos=0; pos<associativity; pos++ )
    if( (set[pos].tag == tag) && ( set[pos].flags & VALID ) )
      break;
  assert( pos != associativity ); // tag must be in the set
  set[pos].timeStamp = GlobalTime; // update timeStamp
  [self increaseAccessCounterOn:&set[pos].recentAccessCount];

  if( set[pos].flags & MEMRISTIVE_MODE )
    for( int i=0; i<blockSize; i++ )
      set[pos].toggleByteCount[i] += loadFromMemristorPenalty;
  else
    for( int i=0; i<blockSize; i++ )
      set[pos].toggleByteCount[i] += loadFromCRSPenalty;

  if(hybridEnabled)
    set[pos].flags |= MEMRISTIVE_MODE; // Mark page as in "Memristive Mode"
}

- (void) markTag:(unsigned long int)tag
           onSet:(struct CacheEntry*)set
         asDirty:(BOOL)dirty
{
  int pos;
  for( pos=0; pos<associativity; pos++ )
    if( (set[pos].tag == tag) && ( set[pos].flags & VALID ) )
      break;
  assert( pos != associativity ); // tag must be in the set
  
  if( dirty )
    set[pos].flags |= DIRTY; // dirty
  else
    set[pos].flags &= ~DIRTY; // not dirty
}

- (void) deactivateUnsedBlocks
{
  assert(hybridEnabled);
  for( int i=0; i<sets; i++ ){
    for( int j=0; j<associativity; j++ ){
      if( (memoryArray[i][j].flags & MEMRISTIVE_MODE) && (memoryArray[i][j].recentAccessCount == 0) ){
        memoryArray[i][j].flags &= ~MEMRISTIVE_MODE; // put block in CRS mode
        for( int k=0; k<blockSize; k++ )
          memoryArray[i][j].toggleByteCount[k] += deactivationPenalty; // update toggle count accordingly
      }
      [self decreaseAccessCounterOn:&memoryArray[i][j].recentAccessCount];
    }
  }
}

- (void) increaseAccessCounterOn:(unsigned long int*)address
{
  *address = *address * 2 + 1;
}

- (void) decreaseAccessCounterOn:(unsigned long int*)address
{
  *address = *address / 2;
  //*address = 0;
}

- (void) printConfiguration
{
  printf("Cache name: %s\n", [name UTF8String]);
  printf("Number of sets: %lu\n", sets);
  printf("Associativity: %lu\n", associativity);
  printf("Block size: %lu B\n", blockSize);
  printf("Capacity: %lu B\n", capacityInBytes);
  printf("Bits for number of sets: %lu\n", setsBits);
  printf("Bits for associativity: %lu\n", associativityBits);
  printf("Bits for block size: %lu\n", blockSizeBits);
  printf("Index offset: %lu\n", indexOffset);
  printf("Index mask: "BYTETOBINARYPATTERN, BYTETOBINARY(indexMask));
  printf("Block address mask: "BYTETOBINARYPATTERN, BYTETOBINARY(blockAddressMask));
  printf("Tag offset: %lu\n", tagOffset);
}

- (double) activeFraction
{
  unsigned long int availablePositions = sets * associativity;
  unsigned long int occupiedPositions = 0;
  for( int i=0; i<sets; i++ )
    for( int j=0; j<associativity; j++ )
      if( memoryArray[i][j].flags & VALID )
        occupiedPositions++;
  return (double) occupiedPositions/availablePositions;
}

- (double) memristiveFraction
{
  unsigned long int availablePositions = sets * associativity;
  unsigned long int occupiedPositions = 0;
  for( int i=0; i<sets; i++ )
    for( int j=0; j<associativity; j++ )
      if( memoryArray[i][j].flags & MEMRISTIVE_MODE )
        occupiedPositions++;
  return (double) occupiedPositions/availablePositions;
}

- (void) printCapacity
{
  int c = 0;
  unsigned long int n = capacityInBytes;
  while(n){
    n = n >> 1;
    c++;
  }
  c--;
  int unit_n = c/10;
  char unit[3] = "B";
  switch (unit_n) {
    case 0:
      strcpy(unit, "B");
      break;
    case 1:
      strcpy(unit, "KB");
      break;
    case 2:
      strcpy(unit, "MB");
      break;
    case 3:
      strcpy(unit, "GB");
      break;
    case 4:
      strcpy(unit, "TB");
      break;
    case 5:
      strcpy(unit, "PB");
      break;
    case 6:
      strcpy(unit, "EB");
      break;
    default:
      break;
  }
  
  int number = 1 << (c%10);
  sprintf(memoryCapacity, "%d%s", number, unit);
  printf(" -** %s memory capacity: %s  **-\n", [name UTF8String], memoryCapacity);
}

- (unsigned long int*) computeToggleByPage
{
  if( tCountByPage == NULL )
    tCountByPage = (unsigned long int*) malloc( sizeof(unsigned long int) * pages );
  assert( tCountByPage != NULL );
  unsigned long int pageIndex = 0;
  for( int i=0; i<sets; i++ ){
    for( int j=0; j<associativity; j++ ){
      unsigned long int tPageCount = 0;
      for( int k=0; k<blockSize; k++ ){
        tPageCount += memoryArray[i][j].toggleByteCount[k];
      }
      tCountByPage[pageIndex++] = tPageCount;
    }
  }
  assert( pageIndex == pages );
  return tCountByPage;
}

- (unsigned long int*) computeToggleByByte
{
  if( tCountByByte == NULL )
    tCountByByte = (unsigned long int*) malloc( sizeof(unsigned long int) * bytes );
  assert( tCountByByte != NULL );
  unsigned long int byteIndex = 0;
  for( int i=0; i<sets; i++ ){
    for( int j=0; j<associativity; j++ ){
      for( int k=0; k<blockSize; k++ ){
        tCountByByte[byteIndex++] = memoryArray[i][j].toggleByteCount[k];
      }
    }
  }
  assert( byteIndex == bytes );
  return tCountByByte;
}

- (void) resetEndurance
{
  for( int i=0; i<sets; i++ ){
    for( int j=0; j<associativity; j++ ){
      for( int k=0; k<blockSize; k++ ){
        memoryArray[i][j].toggleByteCount[k] = 0;
      }
    }
  }
}

- (NSString*) memoryCapacity
{
  return [NSString stringWithFormat:@"%s", memoryCapacity];
}

@end
