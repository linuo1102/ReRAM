/*
 * V2PMap.m
 * Virtual to Physical Mapping
 *
 * Created by Miguel Lastras on April 29, 2015
 */

#import "V2PMap.h"

const int __endian_bit = 1;
#define is_bigendian() ( (*(char*)&__endian_bit) == 0 )
#define PAGEMAP_ENTRY 8
#define GET_BIT(X,Y) (X & ((uint64_t)1<<Y)) >> Y
#define GET_PFN(X) X & 0x7FFFFFFFFFFFFF

@implementation V2PMap

@synthesize foundCounter;
@synthesize notFoundCounter;
@synthesize swappedCounter;

- (unsigned long int) getPhysicalAddressFrom:(unsigned long int)address
{
  // Check first if it is cached:
  unsigned long int pfn;
  unsigned long int vfn = address >> HOST_PAGESIZE_BITS;
  unsigned long int offset = address & (HOST_PAGESIZE-1UL);
  if ( (pfn = [hashTable getKeyOnAddress:vfn]) ){
    foundCounter++;
    return (pfn<<HOST_PAGESIZE_BITS)|offset;
  }
  
  // if not cached, extract page from the 'pagemap' file
  unsigned long int file_offset = vfn * PAGEMAP_ENTRY;
  fseek(pagemap, file_offset, SEEK_SET);
  unsigned long int read_val;
  fread(&read_val, sizeof(read_val), 1, pagemap);
  
  // if not found, return 0 (skip this address for now)
  if( !(GET_BIT(read_val, 63)) ){
    notFoundCounter++;
    return 0;
  }
  
  foundCounter++;
  
  pfn = GET_PFN(read_val);

  // insert the pfn in the hash table
  [hashTable insertKey:pfn];
  
  return (pfn<<HOST_PAGESIZE_BITS)|offset;
}

- (id) initWithFileName:(NSString*)fileName
{
  self = [super init];
  if(self != nil){
    foundCounter = 0;
    notFoundCounter = 0;
    swappedCounter = 0;
    pagemap = fopen([fileName UTF8String], "rb");
    if(pagemap == NULL)
      printf("Cannot find '%s' file!\n", [fileName UTF8String]);
    hashTable = [[HPTable alloc] initWithB3:12 b2:12 b1:12];
  }
  return self;
}



- (void) releaseMemory
{
  [hashTable releaseMemory];
  fclose(pagemap);
}

@end
