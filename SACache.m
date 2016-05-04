/*
 * SACache.m
 * Set Associative Cache
 *
 * Created by Miguel Lastras on Feb 19, 2015
 */

#import "SACache.h"
#import "GlobalFunctions.h"

@implementation SACache

@synthesize name;
@synthesize sets;
@synthesize associativity;
@synthesize blockSize;
@synthesize indexOffset;
@synthesize indexMask;
@synthesize blockAddressMask;
@synthesize tagOffset;
@synthesize accessCount;
@synthesize hits;
@synthesize misses;
@synthesize tagArray;

- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read
{
  accessCount++;
  unsigned long int blockAddress = address & blockAddressMask;
  unsigned long int index = (address & indexMask) >> indexOffset;
  unsigned long int tag = address >> tagOffset;
  
  if( [self lookupTag:tag onSet:tagArray[index]] ){
    hits++;
    [self updateTag:tag onSet:tagArray[index]];
  }
  else{
    misses++;
    [next accessBlock:blockAddress ofSize:blockSize readOperation:YES]; // bring the block from the next level
    unsigned long int evictedTag = [self insertTag:tag onSet:tagArray[index]]; // insert it
    
    // handle the possible eviction
    if( evictedTag != ULONG_MAX ){
      unsigned long int evictedBlockAddress = evictedTag << tagOffset | (index << indexOffset);
      [next accessBlock:evictedBlockAddress ofSize:blockSize readOperation:NO]; // write back the eviction
    }
  }
}

- (id) initWithSetsBits:(unsigned long int)sb
      associativityBits:(unsigned long int)ab
      bytesPerBlockBits:(unsigned long int)bb
              nextLevel:(id)theNext
                   name:(NSString*)theName
{
  setsBits = sb;
  associativityBits = ab;
  blockSizeBits = bb;
  unsigned long int s = 1UL << sb;
  unsigned long int a = 1UL << ab;
  unsigned long int b = 1UL << bb;
  return [self initWithSets:s associativity:a bytesPerBlock:b nextLevel:theNext name:theName];
}

- (id) initWithSets:(unsigned long int)s
      associativity:(unsigned long int)a 
      bytesPerBlock:(unsigned long int)b
          nextLevel:(id)theNext
               name:(NSString*)theName
{ 
  //assert(theNext != nil);
  self = [super init];
  if(self != nil){
    name = theName;
    sets = s;
    associativity = a;
    blockSize = b;
    capacityInBytes = s*a*b;
    setsBits = [GlobalFunctions log2floor:s];
    associativityBits = [GlobalFunctions log2floor:a];
    blockSizeBits = [GlobalFunctions log2floor:b];
    indexOffset = blockSizeBits;
    indexMask = (sets - 1UL) << blockSizeBits;
    blockAddressMask = ~(blockSize - 1UL);
    tagOffset = blockSizeBits + setsBits;
    accessCount = 0;
    hits = 0;
    misses = 0;
    next = theNext;

    // allocate memory for the tag array
    tagArray = (unsigned long int**) malloc(sets * sizeof(unsigned long int*));
    for( int i=0; i<sets; i++ ){
      tagArray[i] = (unsigned long int*) malloc(associativity * sizeof(unsigned long int));
    }
    // init the tag array
    for( int i=0; i<sets; i++ )
      for( int j=0; j<associativity; j++ )
        tagArray[i][j] = ULONG_MAX;
  }
  return self;
}

- (void) releaseMemory
{
  for( int i=0; i<sets; i++ ){
    assert( tagArray[i] != NULL );
    free(tagArray[i]);
  }
  assert(tagArray != NULL);
  free(tagArray);
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

- (unsigned long int) insertTag:(unsigned long int)tag
                          onSet:(unsigned long int*)set
{
  int pos;
  for( pos=0; pos<associativity; pos++ )
    if( set[pos] == ULONG_MAX )
      break;
  if( pos < associativity ){ // there is a position available
    set[pos] = tag; // insert it...
    [self updateTag:tag onSet:set]; // ... and set it as the MRU
    return ULONG_MAX; // no eviction was necessary
    // Since 'ULONG_MAX' is an invalid address, we use it to
    // notify that no eviction was needed.
  }
  // If we made it up to here, there was no position available  
  unsigned long int evicted = set[associativity-1]; // extract the LRU
  set[associativity-1] = tag; // insert the incoming tag ...
  [self updateTag:tag onSet:set]; // ... move it as the MRU
  return evicted;
}

- (BOOL) lookupTag:(unsigned long int)tag
             onSet:(unsigned long int*)set
{
  for( int i=0; i<associativity; i++ )
    if(set[i] == tag)
      return YES;
  return NO;
}

// The update method sets the tag as the most recently used
- (void) updateTag:(unsigned long int)tag
             onSet:(unsigned long int*)set
{
  int pos;
  for( pos=0; pos<associativity; pos++ )
    if( set[pos] == tag )
      break;
  assert( pos != associativity );
  
  unsigned long int aux = set[pos];
  for( int i=pos; i>0; i-- )
    set[i] = set[i-1];
  set[0] = aux;
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
      if(tagArray[i][j] != ULONG_MAX)
        occupiedPositions++;
  return (double) occupiedPositions/availablePositions;
}

@end
