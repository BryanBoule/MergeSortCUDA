// Author Bryan Boule : bryanboule@gmail.com

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Chose list length
//define taille_a 10
//define taille_b 10

__global__ void parallel_merge_path(int *A, int *B, int *M, int taille_a, int taille_b){
	
	// Define variables
	int i = threadIdx.x+blockIdx.x*blockDim.x;
	int atop;
	int btop;
	int abottom;
	int offset;
	int ai;
	int bi;
	if (i > taille_a){
		atop = taille_a;
		btop = i - taille_a;
	} else {
		atop = i;
		btop = 0;
	}
	abottom = btop;
	while (1){
		offset = abs(atop - abottom)/2;
		ai = atop - offset;
		bi = btop + offset;
		if (ai >= 0 && bi <= taille_b && (ai == taille_a || bi == 0 || A[ai] > B[bi-1])){
			if (bi == taille_b || ai == 0 || A[ai-1] <= B[bi]){
				if ((ai < taille_a) && ((bi == taille_b) || (A[ai] <= B[bi]))){
					M[i] = A[ai];
				} else {
					M[i] = B[bi];
				}
				break;
			} else {
				atop = ai - 1;
				btop = bi + 1;
			}
		} else {
			abottom = ai + 1;
		}
	}
}

int main(){
	
	// Define variables
	int *a_array;
	int *b_array;
	int *m_array;
	int *aGPU, *bGPU, *mGPU;
	cudaEvent_t start, stop;

	int taille_a = 1027;
	int taille_b = 2053;
	
	float TimeVar;


	// Allocate memory
	a_array = (int *)malloc(sizeof(int)*taille_a);
    b_array = (int *)malloc(sizeof(int)*taille_b);
	m_array = (int *)malloc(sizeof(int)*(taille_a + taille_b));

	// Test on sorted separated list generated with increasing function
	for(int i=0; i<taille_a; i++){
		a_array[i] = 3*i+2;
	}
	for(int j=0; j<taille_b; j++){
		b_array[j] = 2*j+4;
	}
	
	for(int j=0; j<(taille_a+taille_b); j++){
		m_array[j] = 0;
	}

	cudaMalloc(&aGPU, taille_a*sizeof(int));
	cudaMalloc(&bGPU, taille_b*sizeof(int));
	cudaMalloc(&mGPU, (taille_a+taille_b)*sizeof(int));
	
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	
	cudaMemcpy(aGPU,a_array,taille_a*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(bGPU,b_array,taille_b*sizeof(int), cudaMemcpyHostToDevice);

	cudaEventRecord(start,0);
	parallel_merge_path<<<(1+(taille_a+taille_b)/1024), (taille_a+taille_b)/(1+(taille_a + taille_b)/1024) + ((taille_a + taille_b)%(1+(taille_a+taille_b)/1024))>>>(aGPU,bGPU,mGPU,taille_a, taille_b);
	cudaDeviceSynchronize();
	cudaMemcpy(m_array, mGPU,(taille_a+taille_b)*sizeof(int), cudaMemcpyDeviceToHost);

	cudaEventRecord(stop,0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&TimeVar, start, stop);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	
	printf("Temps d'éxécution : %f\n", TimeVar);
	
	cudaFree(aGPU);
	cudaFree(bGPU);
	cudaFree(mGPU);
	
	// Display result
    for (int i=0; i <(taille_a+taille_b); i++){
        printf("%d  ", m_array[i]);
	}
	printf("\n");
	
	// Free memory
	free(a_array);
	free(b_array);
	free(m_array);

	return 0;
}
