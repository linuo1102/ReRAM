/*
 * HHTable.m
 * Hierarchical Hash Table for the Endurance counters
 *
 * Created by Miguel Lastras on Feb 24, 2015
 */

#import "HHTable.h"
#import "GlobalFunctions.h"

@implementation HHTable

@synthesize pages;
@synthesize bytes;

/*
@synthesize s1Offset;
@synthesize s2Offset;
@synthesize s3Offset;
@synthesize s4Offset;
@synthesize s1BlockOffset;
@synthesize s2BlockOffset;
@synthesize s3BlockOffset;
@synthesize s4BlockOffset;
@synthesize s1Mask;
@synthesize s2Mask;
@synthesize s3Mask;
@synthesize s4Mask;
@synthesize hashTable;
*/

- (id) initWithB4:(unsigned long int)b4
               b3:(unsigned long int)b3
               b2:(unsigned long int)b2
               b1:(unsigned long int)b1
{
  assert( (b1+b2+b3+b4) == ADDRESS_SPACE );
  self = [super init];
  if(self != nil){
    s1Offset = 0;
    s2Offset = b1;
    s3Offset = b1 + b2;
    s4Offset = b1 + b2 + b3;
    s1BlockSize = 1UL << b1;
    s2BlockSize = 1UL << b2;
    s3BlockSize = 1UL << b3;
    s4BlockSize = 1UL << b4;
    s1Mask = (s1BlockSize - 1UL) << s1Offset;
    s2Mask = (s2BlockSize - 1UL) << s2Offset;
    s3Mask = (s3BlockSize - 1UL) << s3Offset;
    s4Mask = (s4BlockSize - 1UL) << s4Offset;
    hashTable = [self initLevel4];
    pages = 0;
    bytes = 0;
  }
  //printf("s1Mask: "BYTETOBINARYPATTERN, BYTETOBINARY(s1Mask));
  //printf("s2Mask: "BYTETOBINARYPATTERN, BYTETOBINARY(s2Mask));
  //printf("s3Mask: "BYTETOBINARYPATTERN, BYTETOBINARY(s3Mask));
  //printf("s4Mask: "BYTETOBINARYPATTERN, BYTETOBINARY(s4Mask));
  return self;
}

- (void) allocateSelectAddress:(unsigned long int)address
{
  L4_index = (address & s4Mask) >> s4Offset;
  L3_index = (address & s3Mask) >> s3Offset;
  L2_index = (address & s2Mask) >> s2Offset;
  L1_index = (address & s1Mask) >> s1Offset;
  if( hashTable[L4_index] == NULL )
    hashTable[L4_index] = [self initLevel3];
  if( hashTable[L4_index][L3_index] == NULL )
    hashTable[L4_index][L3_index] = [self initLevel2];
  if( hashTable[L4_index][L3_index][L2_index] == NULL )
    hashTable[L4_index][L3_index][L2_index] = [self initLevel1];
}

- (unsigned long int****) initLevel4
{
  unsigned long int ****table = (unsigned long int****) malloc( sizeof(unsigned long int***) * s4BlockSize );
  assert( table != NULL );
  int i;
  for( i=0; i<s4BlockSize; i++)
    table[i] = NULL;
  return table;
}

- (unsigned long int***) initLevel3
{
  unsigned long int ***table = (unsigned long int***) malloc( sizeof(unsigned long int**) * s3BlockSize );
  assert( table != NULL );
  int i;
  for( i=0; i<s3BlockSize; i++)
    table[i] = NULL;
  return table;
}

- (unsigned long int**) initLevel2
{
  unsigned long int **table = (unsigned long int**) malloc( sizeof(unsigned long int*) * s2BlockSize );
  assert( table != NULL );
  int i;
  for( i=0; i<s2BlockSize; i++)
    table[i] = NULL;
  return table;
}

- (unsigned long int*) initLevel1
{
  unsigned long int *table = (unsigned long int*) malloc( sizeof(unsigned long int) * s1BlockSize );
  assert( table != NULL );
  int i;
  for( i=0; i<s1BlockSize; i++)
    table[i] = 0;
  return table;
}

- (void) releaseMemory
{
  if( hashTable != NULL ){
    for(int L4=0; L4<s4BlockSize; L4++){
      if( hashTable[L4] != NULL ){
        for(int L3=0; L3<s3BlockSize; L3++){
          if( hashTable[L4][L3] != NULL ){
            for(int L2=0; L2<s2BlockSize; L2++){
              if( hashTable[L4][L3][L2] != NULL ){
                free(hashTable[L4][L3][L2]);
              }
            }
            free(hashTable[L4][L3]);
          }
        }
        free(hashTable[L4]);
      }
    }
    free(hashTable);
  }
  if( eCountByPage != NULL ) free(eCountByPage);
  if( eCountByByte != NULL ) free(eCountByByte);
}

- (unsigned long int) numberOfPages
{
  pages = 0;
  for( int L4=0; L4<s4BlockSize; L4++ )
    if( hashTable[L4] != NULL )
      for( int L3=0; L3<s3BlockSize; L3++ )
        if( hashTable[L4][L3] != NULL )
          for( int L2=0; L2<s2BlockSize; L2++ )
            if( hashTable[L4][L3][L2] != NULL )
              pages++;
  return pages;
}

- (unsigned long int) numberOfBytes
{ 
  bytes = [self numberOfPages] * s1BlockSize;
  return bytes;
}

- (void) increasePageEnduranceBy:(unsigned long int)amount
{
  for( int i=0; i<s1BlockSize; i++ )
    hashTable[L4_index][L3_index][L2_index][i] += amount;
}

- (void) increaseByteEnduranceBy:(unsigned long int)amount
{
  hashTable[L4_index][L3_index][L2_index][L1_index] += amount;
}

- (void) increaseBlockEnduranceOfSize:(unsigned long int)size
                           withAmount:(unsigned long int)amount
{
  for( int i=0; i<size; i++ ){
    assert( (L1_index+i) <= s1BlockSize );
    hashTable[L4_index][L3_index][L2_index][L1_index+i] += amount;
  }
}

- (void) resetEndurance{
  for( int L4=0; L4<s4BlockSize; L4++ )
    if( hashTable[L4] != NULL )
      for( int L3=0; L3<s3BlockSize; L3++ )
        if( hashTable[L4][L3] != NULL )
          for( int L2=0; L2<s2BlockSize; L2++ )
            if( hashTable[L4][L3][L2] != NULL )
              for( int L1=0; L1<s1BlockSize; L1++ )
                hashTable[L4][L3][L2][L1] = 0;
}

- (unsigned long int) computeTotalEnduranceWithReset:(BOOL)reset
{
  unsigned long int total_endurance_count = 0;
  unsigned long int L1, L2, L3, L4;
  for( L4=0; L4<s4BlockSize; L4++ )
    if( hashTable[L4] != NULL )
      for( L3=0; L3<s3BlockSize; L3++ )
        if( hashTable[L4][L3] != NULL )
          for( L2=0; L2<s2BlockSize; L2++ )
            if( hashTable[L4][L3][L2] != NULL )
              for( L1=0; L1<s1BlockSize; L1++ ){
                total_endurance_count += hashTable[L4][L3][L2][L1];
                if(reset)
                  hashTable[L4][L3][L2][L1] = 0;
              }
  
  return total_endurance_count;
}

- (unsigned long int*) computeEnduranceByPage
{
  unsigned long int numberOfPages = [self numberOfPages];
  eCountByPage = (unsigned long int*) malloc( sizeof(unsigned long int) * numberOfPages );
  assert( eCountByPage != NULL );
  unsigned long int pageIndex = 0;
  for( int L4=0; L4<s4BlockSize; L4++ )
    if( hashTable[L4] != NULL )
      for( int L3=0; L3<s3BlockSize; L3++ )
        if( hashTable[L4][L3] != NULL )
          for( int L2=0; L2<s2BlockSize; L2++ )
            if( hashTable[L4][L3][L2] != NULL ){
              unsigned long int ePageCount = 0;
              for( int L1=0; L1<s1BlockSize; L1++ )
                ePageCount += hashTable[L4][L3][L2][L1];
              eCountByPage[pageIndex++] = ePageCount;
            }
  assert( pageIndex == numberOfPages );
  return eCountByPage;
}

- (unsigned long int*) computeEnduranceByByte
{
  unsigned long int numberOfBytes = [self numberOfBytes];
  eCountByByte = (unsigned long int*) malloc( sizeof(unsigned long int) * numberOfBytes );
  assert( eCountByPage != NULL );
  unsigned long int byteIndex = 0;
  for( int L4=0; L4<s4BlockSize; L4++ )
    if( hashTable[L4] != NULL )
      for( int L3=0; L3<s3BlockSize; L3++ )
        if( hashTable[L4][L3] != NULL )
          for( int L2=0; L2<s2BlockSize; L2++ )
            if( hashTable[L4][L3][L2] != NULL )
              for( int L1=0; L1<s1BlockSize; L1++ )
                eCountByByte[byteIndex++] = hashTable[L4][L3][L2][L1];
  assert( byteIndex == numberOfBytes );
  return eCountByByte;
}

// I still need methods to computer the endurance at the
// word, page, block and total levels. If well made, 
// this is what I will use to report my results.

@end
