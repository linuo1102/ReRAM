/*
 * HPTable.m
 * Hierarchical Page Hash Table
 *
 * Created by Miguel Lastras on May 1, 2015
 */

#import "HPTable.h"

@implementation HPTable

- (id) initWithB3:(unsigned long int)b3
               b2:(unsigned long int)b2
               b1:(unsigned long int)b1
{
  assert( (b1+b2+b3) == (ADDRESS_SPACE-HOST_PAGESIZE_BITS) );
  self = [super init];
  if(self != nil){
    s1Offset = 0;
    s2Offset = b1;
    s3Offset = b1 + b2;
    s1BlockSize = 1UL << b1;
    s2BlockSize = 1UL << b2;
    s3BlockSize = 1UL << b3;
    s1Mask = (s1BlockSize - 1UL) << s1Offset;
    s2Mask = (s2BlockSize - 1UL) << s2Offset;
    s3Mask = (s3BlockSize - 1UL) << s3Offset;
    hashTable = [self initLevel3];
    pages = 0;
  }
  return self;
}

- (unsigned long int) getKeyOnAddress:(unsigned long int)address
{
  L3_index = (address & s3Mask) >> s3Offset;
  L2_index = (address & s2Mask) >> s2Offset;
  L1_index = (address & s1Mask) >> s1Offset;
  if( hashTable[L3_index] == NULL )
    hashTable[L3_index] = [self initLevel2];
  if( hashTable[L3_index][L2_index] == NULL )
    hashTable[L3_index][L2_index] = [self initLevel1];
  return hashTable[L3_index][L2_index][L1_index];
}

- (void) insertKey:(unsigned long int)key
{
  hashTable[L3_index][L2_index][L1_index] = key;
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
    for(int L3=0; L3<s3BlockSize; L3++){
      if( hashTable[L3] != NULL ){
        for(int L2=0; L2<s2BlockSize; L2++){
          if( hashTable[L3][L2] != NULL ){
            free(hashTable[L3][L2]);
          }
        }
        free(hashTable[L3]);
      }
    }
    free(hashTable);
  }
}

- (unsigned long int) numberOfPages
{
  pages = 0;
  for( int L3=0; L3<s3BlockSize; L3++ )
    if( hashTable[L3] != NULL )
      for( int L2=0; L2<s2BlockSize; L2++ )
        if( hashTable[L3][L2] != NULL )
          for( int L1=0; L1<s1BlockSize; L1++ )
            if( hashTable[L3][L2][L1] != 0 )
              pages++;
  return pages;
}

- (void) invalidateKeyOnAddress:(unsigned long int)address
{
  L3_index = (address & s3Mask) >> s3Offset;
  L2_index = (address & s2Mask) >> s2Offset;
  L1_index = (address & s1Mask) >> s1Offset;
  
  assert(hashTable[L3_index] != NULL);
  assert(hashTable[L3_index][L2_index] != NULL);
  assert(hashTable[L3_index][L2_index][L1_index] != 0); // it has to, if key is valid
  
  hashTable[L3_index][L2_index][L1_index] = 0; // invalidate it
}

- (void) invalidateAllEntries{
  for( int L3=0; L3<s3BlockSize; L3++ )
    if( hashTable[L3] != NULL )
      for( int L2=0; L2<s2BlockSize; L2++ )
        if( hashTable[L3][L2] != NULL )
          for( int L1=0; L1<s1BlockSize; L1++ )
            hashTable[L3][L2][L1] = 0;
}


@end
