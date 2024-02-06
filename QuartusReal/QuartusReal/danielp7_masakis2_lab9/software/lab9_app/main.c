/************************************************************************
Lab 9 Nios Software

Dong Kai Wang, Fall 2017
Christine Chen, Fall 2013

For use with ECE 385 Experiment 9
University of Illinois ECE Department
************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include "aes.h"

// Pointer to base address of AES module, make sure it matches Qsys
volatile unsigned int * AES_PTR = (unsigned int *) 0x00000040;

// Execution mode: 0 for testing, 1 for benchmarking
int run_mode = 0;

/** charToHex
 *  Convert a single character to the 4-bit value it represents.
 *  
 *  Input: a character c (e.g. 'A')
 *  Output: converted 4-bit value (e.g. 0xA)
 */
char charToHex(char c)
{
	char hex = c;

	if (hex >= '0' && hex <= '9')
		hex -= '0';
	else if (hex >= 'A' && hex <= 'F')
	{
		hex -= 'A';
		hex += 10;
	}
	else if (hex >= 'a' && hex <= 'f')
	{
		hex -= 'a';
		hex += 10;
	}
	return hex;
}

/** charsToHex
 *  Convert two characters to byte value it represents.
 *  Inputs must be 0-9, A-F, or a-f.
 *  
 *  Input: two characters c1 and c2 (e.g. 'A' and '7')
 *  Output: converted byte value (e.g. 0xA7)
 */
char charsToHex(char c1, char c2)
{
	char hex1 = charToHex(c1);
	char hex2 = charToHex(c2);
	return (hex1 << 4) + hex2;
}

// rotates the words positions using a temp variable
void rotWord(unsigned char* word) {
	unsigned char temp;
	temp = word[0];
	word[0] = word[1];
	word[1] = word[2];
	word[2] = word[3];
	word[3] = temp;

}

// generates round keys based on previous round keys
void keyExpansion(unsigned char* key, unsigned char* keySchedule) {

	int i, j;

	// first 4 are as same as key
	for(i=0; i<4; i++){
		for(j=0; j<4; j++){
			keySchedule[i*4 + j] = key[i*4 + j];
		}
	}

	unsigned char temp[4];
	// generating round keys for encryption round and last round
	for(i=4; i<44; i++){

		for(j=0; j<4; j++){
			temp[j] = keySchedule[(i-1)*4 + j];
		}
		// when index is multiple of 4, rotate words and call subBytes and XOR it with corresponding Rcon value
		if (i%4==0){
			/*rotWord(temp);
			printf("%u", temp);*/
			unsigned char temptwo;
			temptwo = temp[0];
			temp[0] = temp[1];
			temp[1] = temp[2];
			temp[2] = temp[3];
			temp[3] = temptwo;

	/*		printf("rot: %u %u %u %u", temp[0], temp[1], temp[2], temp[3]);
			printf("\n");
			printf("Rcon: %u", Rcon[i/4]);
			printf("\n");
			printf("xor: "); */
			for(j=0; j<4; j++){

				//temp[j] = subBytes(temp[j]) ^ Rcon[i/4];
				temp[j] = aes_sbox[temp[j]];

				if (j==0){
					temp[j] = temp[j] ^ (Rcon[i/4]>>24);
				}


				//printf("%u ", temp[j]);

			}
		//	printf("\n");
		}

		// assign computed valuesss to keySchedule
		for(j = 0; j < 4; j++) {
			keySchedule[i*4 + j] = temp[j] ^ keySchedule[(i-4)*4+j];
		}
	}
}

// we XOR The state with the round key from the key schedule to update the new state
void addRoundKey (unsigned char* state, unsigned char* keySchedule, int counter) {
	int i;
	for (i = 0; i < 16; i++) {
		state[i] = state[i] ^ keySchedule[i + counter * 16];
	}
}

//retrieve the sub byte data
unsigned char subBytes(unsigned char input) {
	return aes_sbox[(input)];
}
//Loop to get every sub byte data
/*
void loopSubBytes(unsigned char* state) {
	int i;
	for (i = 0; i < 16; i++) {
		state[i] = subBytes(state[i]);
	}
}*/

//shift the top row none, 2nd row over 1, 3rd row over 2, and last row over 3
void shiftRows(unsigned char* state) {
	unsigned char temp;
	temp = state[1];
	state[1] = state[5];
	state[5] = state[9];
	state[9] = state[13];
	state[13] = temp;

	temp = state[2];
	state[2] = state[10];
	state[10] = temp;

	temp = state[15];
	state[15] = state[11];
	state[11] = state[7];
	state[7] = state[3];
	state[3] = temp;

	temp = state[6];
	state[6] = state[14];
	state[14] = temp;

}

//modulo multiply in rijndael's galois field with the state given
void mixColumns(unsigned char* state) {
	unsigned char temp[16];
	int i;
	for (i = 0; i < 16; i++) {
		temp[i] = state[i];
	}
	//update each state based on the given algorithm in the instructions
	state[0] = gf_mul[temp[0]][0] ^ gf_mul[temp[1]][1] ^ temp[2] ^ temp[3];
	state[1] = temp[0] ^ gf_mul[temp[1]][0] ^ gf_mul[temp[2]][1] ^ temp[3];
	state[2] = temp[0] ^ temp[1] ^ gf_mul[temp[2]][0] ^ gf_mul[temp[3]][1];
	state[3] = gf_mul[temp[0]][1] ^ temp[1] ^ temp[2] ^ gf_mul[temp[3]][0];

	state[4] = gf_mul[temp[4]][0] ^ gf_mul[temp[5]][1] ^ temp[6] ^ temp[7];
	state[5] = temp[4] ^ gf_mul[temp[5]][0] ^ gf_mul[temp[6]][1] ^ temp[7];
	state[6] = temp[4] ^ temp[5] ^ gf_mul[temp[6]][0] ^ gf_mul[temp[7]][1];
	state[7] = gf_mul[temp[4]][1] ^ temp[5] ^ temp[6] ^ gf_mul[temp[7]][0];

	state[8] = gf_mul[temp[8]][0] ^ gf_mul[temp[9]][1] ^ temp[10] ^ temp[11];
	state[9] = temp[8] ^ gf_mul[temp[9]][0] ^ gf_mul[temp[10]][1] ^ temp[11];
	state[10] = temp[8] ^ temp[9] ^ gf_mul[temp[10]][0] ^ gf_mul[temp[11]][1];
	state[11] = gf_mul[temp[8]][1] ^ temp[9] ^ temp[10] ^ gf_mul[temp[11]][0];

	state[12] = gf_mul[temp[12]][0] ^ gf_mul[temp[13]][1] ^ temp[14] ^ temp[15];
	state[13] = temp[12] ^ gf_mul[temp[13]][0] ^ gf_mul[temp[14]][1] ^ temp[15];
	state[14] = temp[12] ^ temp[13] ^ gf_mul[temp[14]][0] ^ gf_mul[temp[15]][1];
	state[15] = gf_mul[temp[12]][1] ^ temp[13] ^ temp[14] ^ gf_mul[temp[15]][0];
}




/** encrypt
 *  Perform AES encryption in software.
 *
 *  Input: msg_ascii - Pointer to 32x 8-bit char array that contains the input message in ASCII format
 *         key_ascii - Pointer to 32x 8-bit char array that contains the input key in ASCII format
 *  Output:  msg_enc - Pointer to 4x 32-bit int array that contains the encrypted message
 *               key - Pointer to 4x 32-bit int array that contains the input key
 */
void encrypt(unsigned char * msg_ascii, unsigned char * key_ascii, unsigned int * msg_enc, unsigned int * key)
{
	// Implement this function
	unsigned char state[16];
	unsigned char keySchedule[176];
	unsigned char stateOfKey[16];

	int i;
	for (int i = 0; i < 16; i++) {
		state[i] = charsToHex(msg_ascii[2*i], msg_ascii[2*i+1]);
		stateOfKey[i] = charsToHex(key_ascii[2*i], key_ascii[2*i+1]);
	}

	keyExpansion(stateOfKey, keySchedule);
	addRoundKey(state, keySchedule, 0);

	for (i = 1; i < 10; i++) {
		int j;
		for (j = 0; j < 16; j++) {
			state[j] = subBytes(state[j]);
		}
		shiftRows(state);
		mixColumns(state);
		addRoundKey(state, keySchedule, i);
	}

	for (i = 0; i < 16; i++) {
		state[i] = subBytes(state[i]);
	}
	shiftRows(state);
	addRoundKey(state, keySchedule, 10);
	for (i = 0; i < 4; i++) {
		msg_enc[i] = (state[i*4] << 24) + (state[i*4+1] << 16) + (state[i*4+2] << 8) + state[i*4+3];
		key[i] = (stateOfKey[i*4] << 24) + (stateOfKey[i*4+1] << 16) + (stateOfKey[i*4+2] << 8) + stateOfKey[i*4+3];
	}
}

/** decrypt
 *  Perform AES decryption in hardware.
 *
 *  Input:  msg_enc - Pointer to 4x 32-bit int array that contains the encrypted message
 *              key - Pointer to 4x 32-bit int array that contains the input key
 *  Output: msg_dec - Pointer to 4x 32-bit int array that contains the decrypted message
 */
void decrypt(unsigned int * msg_enc, unsigned int * msg_dec, unsigned int * key)
{
	// Implement this function

}

/** main
 *  Allows the user to enter the message, key, and select execution mode
 *
 */
int main()
{
	// Input Message and Key as 32x 8-bit ASCII Characters ([33] is for NULL terminator)
	unsigned char msg_ascii[33];
	unsigned char key_ascii[33];
	// Key, Encrypted Message, and Decrypted Message in 4x 32-bit Format to facilitate Read/Write to Hardware
	unsigned int key[4];
	unsigned int msg_enc[4];
	unsigned int msg_dec[4];

	printf("Select execution mode: 0 for testing, 1 for benchmarking: ");
	scanf("%d", &run_mode);

	if (run_mode == 0) {
		// Continuously Perform Encryption and Decryption
		while (1) {
			int i = 0;
			printf("\nEnter Message:\n");
			scanf("%s", msg_ascii);
			printf("\n");
			printf("\nEnter Key:\n");
			scanf("%s", key_ascii);
			printf("\n");
			encrypt(msg_ascii, key_ascii, msg_enc, key);
			printf("\nEncrpted message is: \n");
			for(i = 0; i < 4; i++){
				printf("%08x", msg_enc[i]);
			}
			printf("\n");
			decrypt(msg_enc, msg_dec, key);
			printf("\nDecrypted message is: \n");
			for(i = 0; i < 4; i++){
				printf("%08x", msg_dec[i]);
			}
			printf("\n");
		}
	}
	else {
		// Run the Benchmark
		int i = 0;
		int size_KB = 2;
		// Choose a random Plaintext and Key
		for (i = 0; i < 32; i++) {
			msg_ascii[i] = 'a';
			key_ascii[i] = 'b';
		}
		// Run Encryption
		clock_t begin = clock();
		for (i = 0; i < size_KB * 64; i++)
			encrypt(msg_ascii, key_ascii, msg_enc, key);
		clock_t end = clock();
		double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
		double speed = size_KB / time_spent;
		printf("Software Encryption Speed: %f KB/s \n", speed);
		// Run Decryption
		begin = clock();
		for (i = 0; i < size_KB * 64; i++)
			decrypt(msg_enc, msg_dec, key);
		end = clock();
		time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
		speed = size_KB / time_spent;
		printf("Hardware Encryption Speed: %f KB/s \n", speed);
	}
	return 0;
}
