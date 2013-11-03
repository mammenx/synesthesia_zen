/*
 * fft.h
 *
 *  Created on: May 2, 2012
 *      Author: mammenx
 */

#ifndef FFT_H_
#define FFT_H_

/* FFT */
void fft(int N, double (*x)[2], double (*X)[2]);

/* IFFT */
void ifft(int N, double (*x)[2], double (*X)[2]);

#endif /* FFT_H_ */
