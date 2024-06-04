/* USER CODE BEGIN Header */
/**
 ******************************************************************************
 * @file           : main.c
 * @brief          : Main program body
 ******************************************************************************
 * @attention
 *
 * Copyright (c) 2024 STMicroelectronics.
 * All rights reserved.
 *
 * This software is licensed under terms that can be found in the LICENSE file
 * in the root directory of this software component.
 * If no LICENSE file comes with this software, it is provided AS-IS.
 *
 ******************************************************************************
 */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */
#include <string.h>
#include <stdio.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef hlpuart1;
UART_HandleTypeDef huart1;
UART_HandleTypeDef huart2;

SPI_HandleTypeDef hspi1;
SPI_HandleTypeDef hspi2;

TIM_HandleTypeDef htim6;

/* USER CODE BEGIN PV */
uint16_t gSPI_Data;
uint16_t gSPI_Data1;
uint16_t gSPI_Data2;
uint8_t gPingPong_Flag = 0;

uint16_t gSPI_Buffer[1024];
int16_t gSPI_RdPtr = 0;
int16_t gSPI_WrPtr = 0;

uint16_t gSPI_RxCnt = 0;
uint8_t gSPI_RxDone = 0;
uint8_t gUART_TxDone = 1;

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_LPUART1_UART_Init(void);
static void MX_USART1_UART_Init(void);
static void MX_USART2_UART_Init(void);
static void MX_SPI1_Init(void);
static void MX_SPI2_Init(void);
static void MX_TIM6_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
//Clock Pre-scale=8-1
//Clock Period=2
//(Main Clock) / (Clock Pre-scale) * (Clock Period)
//32MHz/8=4MHz.  (f=4MHz,t=250nS)
//500nS
void My_Delay_us(uint32_t nus) {
	uint16_t differ = 0xFFFF - nus - 5;
	__HAL_TIM_SetCounter(&htim6, differ);
	HAL_TIM_Base_Start(&htim6);
	while (differ < (0xFFFF - 5)) {
		differ = __HAL_TIM_GetCounter(&htim6);
	}
	HAL_TIM_Base_Stop(&htim6);
}

#define NOP_RATIO 1 //change by your demand.
void My_NOP_Delay(uint32_t cnt) {
	cnt = cnt * NOP_RATIO;
	while (cnt--) {
		__NOP();
	}
}

/* USER CODE END 0 */

/**
 * @brief  The application entry point.
 * @retval int
 */
int main(void)
{

	/* USER CODE BEGIN 1 */
	/* USER CODE END 1 */

	/* MCU Configuration--------------------------------------------------------*/

	/* Reset of all peripherals, Initializes the Flash interface and the Systick. */
	HAL_Init();

	/* USER CODE BEGIN Init */

	/* USER CODE END Init */

	/* Configure the system clock */
	SystemClock_Config();

	/* USER CODE BEGIN SysInit */

	/* USER CODE END SysInit */

	/* Initialize all configured peripherals */
	MX_GPIO_Init();
	MX_LPUART1_UART_Init();
	MX_USART1_UART_Init();
	MX_USART2_UART_Init();
	MX_SPI1_Init();
	MX_SPI2_Init();
	MX_TIM6_Init();
	/* USER CODE BEGIN 2 */
	//Fiber_UART  ---- FPGA 1# UART. (Infra-red Image Sensor)
	//            ---- FPGA 2# UART. (Visible-Light Image Sensor)
	//            ---- MCU LPUART1. (Photo-voltaic Cell: Power Supply Unit)
	//In TMR project, route Fiber_UART to MCU LPUART.
	HAL_GPIO_WritePin(GPIOA, ROUTE_A0_Pin | ROUTE_A1_Pin, GPIO_PIN_RESET);
	/* USER CODE END 2 */

	/* Infinite loop */
	/* USER CODE BEGIN WHILE */
	//Step1: SDI (always keeps HIGH).
	uint16_t SDI_Data1 = 0xFFFF;
	//Transmit an amount of data in blocking mode.
	//HAL_SPI_Transmit(SPI_HandleTypeDef *hspi, uint8_t *pData, uint16_t Size, uint32_t Timeout)
	HAL_SPI_Transmit(&hspi2, (uint8_t*) &SDI_Data1, 1, 0xFFFF);
	HAL_Delay(1);

	//WORKING_MODE=0: Sample1 -> Transmit1 -> Sample2 -> Transmit2 ... ...
	//WORKING_MODE=1: Sample 1024 Points -> Transmit -> Sample 1024 Points -> Transmit ... ...
#if 1
	while(1)
	{
		//Step2: Pull up CNV to generate a rising edge.
		//HAL_GPIO_WritePin(GPIOB, ADC_CNV_Pin, GPIO_PIN_SET);
		GPIOB->BSRR |= ADC_CNV_Pin; //Using Register Operation replace of HAL library.

		//Step3: Waiting ADC Conversion time:>=9.5uS.
		//My_Delay_us(5); //HAL_Delay(1) Depreciated, it takes up much time.
		//__NOP(); __NOP(); __NOP(); __NOP(); __NOP(); //2.2uS*5=11uS.
		//My_NOP_Delay(5);

		//Step4:Pull-down CNV, start to read data.
		//HAL_GPIO_WritePin(GPIOB, ADC_CNV_Pin, GPIO_PIN_RESET);
		GPIOB->BRR |= ADC_CNV_Pin; //Using Register Operation replace of HAL library.
		//My_Delay_us(1); //HAL_Delay(1) Depreciated, it takes up much time.
		//__NOP();
		//My_NOP_Delay(1);

		//Step5: Read Data In.
		//HAL_SPI_Receive_IT(&hspi2,(uint8_t*)gBuffer_SPI,1);
		//HAL_SPI_TransmitReceive_IT(SPI_HandleTypeDef *hspi, uint8_t *pTxData, uint8_t *pRxData, uint16_t Size)
		//HAL_SPI_TransmitReceive_IT(&hspi2, ///<
		//		(uint8_t*) &SDI_Data1, ///<
		//		(uint8_t*) &gSPI_Buffer1[gSPI_WrPtr1++], ///<
		//		2);
		hspi2.Instance->DR=0xFFFF; //MOSI keeps HIGH while reading MISO.
		while(!(hspi2.Instance->SR & SPI_FLAG_RXNE))
		{
			//Waiting for Receive Buffer Not Empty.
		}
		//gSPI_Buffer[gSPI_WrPtr]=hspi2.Instance->DR; //Read
		//gSPI_WrPtr=(gSPI_WrPtr>=1023)?(0):(gSPI_WrPtr++); //Loop buffer to avoid overflow.
		gSPI_Data=hspi2.Instance->DR; //Read

		//Transmit $(0x24) Symbol.
		hlpuart1.Instance->TDR='$';
		//Waiting for Transmit Data Register Empty.
		while(!(hlpuart1.Instance->ISR & USART_ISR_TXE))
		{}

		//Transmit 16-bits ADC Data - HIGH Byte.
		hlpuart1.Instance->TDR=(gSPI_Data>>8);
		//Waiting for Transmit Data Register Empty.
		while(!(hlpuart1.Instance->ISR & USART_ISR_TXE))
		{}

		//Transmit 16-bits ADC Data - LOW Byte.
		hlpuart1.Instance->TDR=(gSPI_Data&0x00FF);
		//Waiting for Transmit Data Register Empty.
		while(!(hlpuart1.Instance->ISR & USART_ISR_TXE))
		{}

		//Transmit !(0x21) Symbol.
		hlpuart1.Instance->TDR='!';
		//Waiting for Transmit Data Register Empty.
		while(!(hlpuart1.Instance->ISR & USART_ISR_TXE))
		{}
	}
#else
	//We sample data continuously to fill buffer, then send data out to find out where the bottleneck is.
	gSPI_WrPtr=0;
	gSPI_RdPtr=0;
	do {
		//Step2: Pull up CNV to generate a rising edge.
		//HAL_GPIO_WritePin(GPIOB, ADC_CNV_Pin, GPIO_PIN_SET);
		GPIOB->BSRR |= ADC_CNV_Pin; //Using Register Operation replace of HAL library.

		//Step3: Waiting ADC Conversion time:>=9.5uS.
		//My_Delay_us(5); //HAL_Delay(1) Depreciated, it takes up much time.
		//__NOP(); __NOP(); __NOP(); __NOP(); __NOP(); //2.2uS*5=11uS.
		//My_NOP_Delay(5);

		//Step4:Pull-down CNV, start to read data.
		//HAL_GPIO_WritePin(GPIOB, ADC_CNV_Pin, GPIO_PIN_RESET);
		GPIOB->BRR |= ADC_CNV_Pin; //Using Register Operation replace of HAL library.
		//My_Delay_us(1); //HAL_Delay(1) Depreciated, it takes up much time.
		//__NOP();
		//My_NOP_Delay(1);

		//Step5: Read Data In.
		//HAL_SPI_Receive_IT(&hspi2,(uint8_t*)gBuffer_SPI,1);
		//HAL_SPI_TransmitReceive_IT(SPI_HandleTypeDef *hspi, uint8_t *pTxData, uint8_t *pRxData, uint16_t Size)
		//HAL_SPI_TransmitReceive_IT(&hspi2, ///<
		//		(uint8_t*) &SDI_Data1, ///<
		//		(uint8_t*) &gSPI_Buffer1[gSPI_WrPtr1++], ///<
		//		2);
		hspi2.Instance->DR=0xFFFF; //MOSI keeps HIGH while reading MISO.
		while(!(hspi2.Instance->SR & SPI_FLAG_RXNE))
		{
			//Waiting for Receive Buffer Not Empty.
		}
		gSPI_Buffer[gSPI_WrPtr]=hspi2.Instance->DR; //Read
		//break do{}while(1) if sample counts reaches 1024.
		if (gSPI_WrPtr >= (1024 - 1)) {
			break;
		}else{
			gSPI_WrPtr++;
		}
	} while (1);

	//Send data out via LPUART1, check SIN wave in Serial Plotter to see if we get a perfect SIN wave.
	for (uint16_t i = 0; i <= (1024-1); i++) {
		//Transmit $(0x24) Symbol.
		hlpuart1.Instance->TDR='$';
		//Waiting for Transmit Data Register Empty.
		while(!(hlpuart1.Instance->ISR & USART_ISR_TXE))
		{}

		//Transmit 16-bits ADC Data - HIGH Byte.
		hlpuart1.Instance->TDR=(gSPI_Buffer[gSPI_RdPtr]>>8);
		//Waiting for Transmit Data Register Empty.
		while(!(hlpuart1.Instance->ISR & USART_ISR_TXE))
		{}

		//Transmit 16-bits ADC Data - LOW Byte.
		hlpuart1.Instance->TDR=(gSPI_Buffer[gSPI_RdPtr]&0x00FF);
		//Waiting for Transmit Data Register Empty.
		while(!(hlpuart1.Instance->ISR & USART_ISR_TXE))
		{}

		//Transmit !(0x21) Symbol.
		hlpuart1.Instance->TDR='!';
		//Waiting for Transmit Data Register Empty.
		while(!(hlpuart1.Instance->ISR & USART_ISR_TXE))
		{}
		gSPI_RdPtr++;
	}
#endif

	//Stop Here.
	 HAL_GPIO_WritePin(GPIOB, IAM_ALIVE_Pin, GPIO_PIN_SET);
	//////////////////////////////////////////////////////////////////////////////////////////
#if 0
	while (1) {
		uint8_t buffer_format[32]; //Maximum value: strlen($65535;)=8
		gSPI_WrPtr1 = 0;
		//		do {
		//Step2: Pull up CNV to generate a rising edge.
		//HAL_GPIO_WritePin(GPIOB, ADC_CNV_Pin, GPIO_PIN_SET);
		GPIOB->BSRR |= ADC_CNV_Pin; //Using Register Operation replace of HAL library.

		//Step3: Waiting ADC Conversion time:>=9.5uS.
		//My_Delay_us(5); //HAL_Delay(1) Depreciated, it takes up much time.
		__NOP();
		__NOP();
		__NOP();
		__NOP();
		__NOP(); //2.2uS*5=11uS.
		//My_NOP_Delay(5);

		//Step4:Pull-down CNV, start to read data.
		//HAL_GPIO_WritePin(GPIOB, ADC_CNV_Pin, GPIO_PIN_RESET);
		GPIOB->BRR |= ADC_CNV_Pin; //Using Register Operation replace of HAL library.
		//My_Delay_us(1); //HAL_Delay(1) Depreciated, it takes up much time.
		//__NOP();
		My_NOP_Delay(1);

		//Only receive single 16-bits.
		//HAL_SPI_Receive_IT(&hspi2,(uint8_t*)gBuffer_SPI,1);
		//HAL_SPI_TransmitReceive_IT(SPI_HandleTypeDef *hspi, uint8_t *pTxData, uint8_t *pRxData, uint16_t Size)
		HAL_SPI_TransmitReceive_IT(&hspi2, ///<
				(uint8_t*) &SDI_Data1, ///<
				(uint8_t*) &gSPI_Data1/*gSPI_Buffer1[gSPI_WrPtr1++]*/, ///<
				2);

		//Here we can't start next sample & transfer immediately.
		//we can't break the data output transfer progress, until we receive Interrupt.
		while (!gSPI_RxDone) {
		}
		gSPI_RxDone = 0;

		//Un-comment this line will cause abnormal SIN wave.
		//Enable this line to keep enough tDIS safe time.
		//My_Delay_us(1);
		__NOP();
		//My_NOP_Delay(1);

		//			if (gSPI_WrPtr1 >= (1024 - 1)) {
		//				break;
		//			}
		//		} while (1);

		//Send data out via LPUART1.
		//		gSPI_RdPtr1 = 0;
		//		for (i = 0; i < (1024 - 1); i++) {
		//			uint8_t buffer_format[32]; //Maximum value: strlen($65535;)=8
		//			sprintf((char*) buffer_format, "$%d;", gSPI_Buffer1[gSPI_RdPtr1++]);
		//			HAL_UART_Transmit(&hlpuart1, ///<
		//					(const uint8_t*) buffer_format, ///<
		//					strlen((char*) buffer_format), 0xFFFF);
		//
		//		}
		sprintf((char*) buffer_format, "$%d;", gSPI_Data1);
		HAL_UART_Transmit(&hlpuart1, ///<
				(const uint8_t*) buffer_format, ///<
				strlen((char*) buffer_format), 0xFFFF);
		//Stop Here to Check data with Serial Plotter to see if we get a perfect SIN wave.
		gSPI_RdPtr1 = 0;
	}
#if 0
	while(1){
		//CAUTION HERE! So weird, What the fucking is going on???
		//Two HAL_GPIO_WritePin() lines take up 4uS, one line takes 2uS!

		//HAL_GPIO_WritePin(GPIOB, IAM_ALIVE_Pin, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOB, TEST_SIG_Pin, GPIO_PIN_SET);
		//Alarming Here, Function Calling will take additional time.
		//Likely, __NOP() takes up 2.2us, but My_NOP_Delay(1) takes up 3.8uS.
		__NOP();

		//HAL_GPIO_WritePin(GPIOB, IAM_ALIVE_Pin, GPIO_PIN_RESET);
		HAL_GPIO_WritePin(GPIOB, TEST_SIG_Pin, GPIO_PIN_RESET);
		__NOP();
	}
#endif
#endif

#if 0 //Ping-Pong operation.
	do {
		if (gPingPong_Flag) {
			/////////////////////////////////////////////////////
			//Write to gSPI_Data1, Read from gSPI_Data2.
			/////////////////////////////////////////////////////

			//3-wires mode.
			//Step2: Pull up CNV to generate a rising edge.
			HAL_GPIO_WritePin(GPIOB, ADC_CNV_Pin, GPIO_PIN_SET);

			//Step3: Waiting ADC Conversion time:>=9.5uS.
			My_Delay_us(5); //HAL_Delay(1) Depreciated, it takes much time.
			//Here I use sprintf() to replicate the effect of My_Delay_us().
			//sprintf((char*) buffer_format, "$%d;", gSPI_Data2);
			//HAL_UART_Transmit_IT(&hlpuart1, ///<
			//		(const uint8_t*) buffer_format, ///<
			//		strlen((char*) buffer_format));

			//Step4:Pull-down CNV, start to read data.
			HAL_GPIO_WritePin(GPIOB, ADC_CNV_Pin, GPIO_PIN_RESET);
			My_Delay_us(1); //HAL_Delay(1) Depreciated, it takes much time.

			//Only receive single 16-bits.
			//HAL_SPI_Receive_IT(&hspi2,(uint8_t*)gBuffer_SPI,1);
			//HAL_SPI_TransmitReceive_IT(SPI_HandleTypeDef *hspi, uint8_t *pTxData, uint8_t *pRxData, uint16_t Size)
			HAL_SPI_TransmitReceive_IT(&hspi2, ///<
					(uint8_t*) &SDI_Data1, ///<
					(uint8_t*) &gSPI_Buffer1[gSPI_WrPtr1++], ///<
					2);
			//Actually we can't start next sample & transfer immediately,
			//we can't break the data output progress,
			//until we get an Transfer Done Interrupt.
			//ADC starts conversion with a rising edge of CNV.

		} else {
			/////////////////////////////////////////////////////////
			//Write to gSPI_Data2, Read from gSPI_Data1.
			/////////////////////////////////////////////////////////

			//Step2: Pull up CNV to generate a rising edge.
			HAL_GPIO_WritePin(GPIOB, ADC_CNV_Pin, GPIO_PIN_SET);

			//Step3: Waiting ADC Conversion time:>=9.5uS.
			My_Delay_us(5); //HAL_Delay(1) Depreciated, it takes much time.
			//Here I use sprintf() to replicate the effect of My_Delay_us().
			//sprintf((char*) buffer_format, "$%d;", gSPI_Data1);
			//HAL_UART_Transmit_IT(&hlpuart1, ///<
			//		(const uint8_t*) buffer_format, ///<
			//		strlen((char*) buffer_format));

			//Step4:Pull-down CNV, start to read data.
			HAL_GPIO_WritePin(GPIOB, ADC_CNV_Pin, GPIO_PIN_RESET);
			My_Delay_us(1); //HAL_Delay(1) Depreciated, it takes much time.

			//Only receive single 16-bits.
			//HAL_SPI_Receive_IT(&hspi2,(uint8_t*)gBuffer_SPI,1);
			//HAL_SPI_TransmitReceive_IT(SPI_HandleTypeDef *hspi, uint8_t *pTxData, uint8_t *pRxData, uint16_t Size)
			HAL_SPI_TransmitReceive_IT(&hspi2, ///<
					(uint8_t*) &SDI_Data1, ///<
					(uint8_t*) &gSPI_Buffer2[gSPI_WrPtr2++], ///<
					2);
		}
		//switching buffer dynamically.
		gPingPong_Flag = !gPingPong_Flag;
		if(gSPI_WrPtr1==1020) //Buffer was filled full, dump data out via LPUART1.
		{
			uint16_t i;
			gSPI_RdPtr1=0;
			gSPI_RdPtr2=0;
			for(i=0;i<1020;i++)
			{
				uint8_t buffer_format[32]; //Maximum value: strlen($65535;)=8
				sprintf((char*) buffer_format, "$%d;", gSPI_Buffer1[gSPI_RdPtr1++]);
				HAL_UART_Transmit_IT(&hlpuart1, ///<
						(const uint8_t*) buffer_format, ///<
						strlen((char*) buffer_format));
				sprintf((char*) buffer_format, "$%d;", gSPI_Buffer2[gSPI_RdPtr2++]);
				HAL_UART_Transmit_IT(&hlpuart1, ///<
						(const uint8_t*) buffer_format, ///<
						strlen((char*) buffer_format));
			}
			gSPI_RdPtr1=0;
			gSPI_RdPtr2=0;
		}


#if 0
		//Dump data out via LPUART1.
		if (gUART_TxDone) {

			gUART_TxDone = 0; //Reset flag.
			//HAL_UART_Transmit(&hlpuart1, (const uint8_t*) &gSPI_Data,2,0xFFFF);
			sprintf((char*) buffer_format, "$%d;", gSPI_Data2);
			HAL_UART_Transmit_IT(&hlpuart1, ///<
					(const uint8_t*) buffer_format, ///<
					strlen((char*) buffer_format));
		}
#endif
	} while (1);
#endif

#if 0
	//https://github.com/CieNTi/serial_port_plotter
	//We use this open-source project to draw realtime curve on PC screen.
	//So we send data with expected format.
	//pc.printf("$%d %d;", rawData, filteredData);

	//HAL_UART_Transmit(UART_HandleTypeDef *huart, const uint8_t *pData, uint16_t Size, uint32_t Timeout)
	//sprintf((char*)buffer_string,"$%d %d;",gBuffer_SPI[0],gBuffer_SPI[0]);
	//Turn PMOS Switch On to Enable Tx Power before sending.
	HAL_GPIO_WritePin(GPIOB, TX_EN_Pin, GPIO_PIN_RESET);
	for (i = 0; i < 1024; i++) {
		//Maximum value: strlen($65535;)=8
		uint8_t buffer_string[32];
		sprintf((char*) buffer_string, "$%d;", gSPI_Buffer[i]);
		HAL_UART_Transmit(&hlpuart1, (const uint8_t*) buffer_string,
				strlen((char*) buffer_string), 0xFFFF);
		//HAL_UART_Transmit(&hlpuart1,"Hello\r\n",strlen("Hello\r\n"),0xFFFF);
	}
	//Turn PMOS Switch Off to Disable Tx Power after sending.
	HAL_Delay(1);
	HAL_GPIO_WritePin(GPIOB, TX_EN_Pin, GPIO_PIN_SET);

	//LED Flash Indicator.
	/*
		 HAL_GPIO_WritePin(GPIOB, IAM_ALIVE_Pin, GPIO_PIN_SET);
		 HAL_Delay(100);
		 HAL_GPIO_WritePin(GPIOB, IAM_ALIVE_Pin, GPIO_PIN_RESET);
		 HAL_Delay(100);
	 */
#endif
	/* USER CODE END WHILE */

	/* USER CODE BEGIN 3 */
	/* USER CODE END 3 */
}

/**
 * @brief System Clock Configuration
 * @retval None
 */
void SystemClock_Config(void)
{
	RCC_OscInitTypeDef RCC_OscInitStruct = {0};
	RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};
	RCC_PeriphCLKInitTypeDef PeriphClkInit = {0};

	/** Configure the main internal regulator output voltage
	 */
	__HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

	/** Initializes the RCC Oscillators according to the specified parameters
	 * in the RCC_OscInitTypeDef structure.
	 */
	RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
	RCC_OscInitStruct.HSEState = RCC_HSE_BYPASS;
	RCC_OscInitStruct.PLL.PLLState = RCC_PLL_NONE;
	if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
	{
		Error_Handler();
	}

	/** Initializes the CPU, AHB and APB buses clocks
	 */
	RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
			|RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
	RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_HSE;
	RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
	RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV1;
	RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

	if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_1) != HAL_OK)
	{
		Error_Handler();
	}
	PeriphClkInit.PeriphClockSelection = RCC_PERIPHCLK_USART1|RCC_PERIPHCLK_USART2
			|RCC_PERIPHCLK_LPUART1;
	PeriphClkInit.Usart1ClockSelection = RCC_USART1CLKSOURCE_PCLK2;
	PeriphClkInit.Usart2ClockSelection = RCC_USART2CLKSOURCE_PCLK1;
	PeriphClkInit.Lpuart1ClockSelection = RCC_LPUART1CLKSOURCE_PCLK1;
	if (HAL_RCCEx_PeriphCLKConfig(&PeriphClkInit) != HAL_OK)
	{
		Error_Handler();
	}
	HAL_RCC_MCOConfig(RCC_MCO1, RCC_MCO1SOURCE_SYSCLK, RCC_MCODIV_1);
}

/**
 * @brief LPUART1 Initialization Function
 * @param None
 * @retval None
 */
static void MX_LPUART1_UART_Init(void)
{

	/* USER CODE BEGIN LPUART1_Init 0 */

	/* USER CODE END LPUART1_Init 0 */

	/* USER CODE BEGIN LPUART1_Init 1 */

	/* USER CODE END LPUART1_Init 1 */
	hlpuart1.Instance = LPUART1;
	hlpuart1.Init.BaudRate = 4000000;
	hlpuart1.Init.WordLength = UART_WORDLENGTH_8B;
	hlpuart1.Init.StopBits = UART_STOPBITS_1;
	hlpuart1.Init.Parity = UART_PARITY_NONE;
	hlpuart1.Init.Mode = UART_MODE_TX_RX;
	hlpuart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	hlpuart1.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
	hlpuart1.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
	if (HAL_UART_Init(&hlpuart1) != HAL_OK)
	{
		Error_Handler();
	}
	/* USER CODE BEGIN LPUART1_Init 2 */

	/* USER CODE END LPUART1_Init 2 */

}

/**
 * @brief USART1 Initialization Function
 * @param None
 * @retval None
 */
static void MX_USART1_UART_Init(void)
{

	/* USER CODE BEGIN USART1_Init 0 */

	/* USER CODE END USART1_Init 0 */

	/* USER CODE BEGIN USART1_Init 1 */

	/* USER CODE END USART1_Init 1 */
	huart1.Instance = USART1;
	huart1.Init.BaudRate = 115200;
	huart1.Init.WordLength = UART_WORDLENGTH_8B;
	huart1.Init.StopBits = UART_STOPBITS_1;
	huart1.Init.Parity = UART_PARITY_NONE;
	huart1.Init.Mode = UART_MODE_TX_RX;
	huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	huart1.Init.OverSampling = UART_OVERSAMPLING_16;
	huart1.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
	huart1.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
	if (HAL_UART_Init(&huart1) != HAL_OK)
	{
		Error_Handler();
	}
	/* USER CODE BEGIN USART1_Init 2 */

	/* USER CODE END USART1_Init 2 */

}

/**
 * @brief USART2 Initialization Function
 * @param None
 * @retval None
 */
static void MX_USART2_UART_Init(void)
{

	/* USER CODE BEGIN USART2_Init 0 */

	/* USER CODE END USART2_Init 0 */

	/* USER CODE BEGIN USART2_Init 1 */

	/* USER CODE END USART2_Init 1 */
	huart2.Instance = USART2;
	huart2.Init.BaudRate = 115200;
	huart2.Init.WordLength = UART_WORDLENGTH_8B;
	huart2.Init.StopBits = UART_STOPBITS_1;
	huart2.Init.Parity = UART_PARITY_NONE;
	huart2.Init.Mode = UART_MODE_TX_RX;
	huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	huart2.Init.OverSampling = UART_OVERSAMPLING_16;
	huart2.Init.OneBitSampling = UART_ONE_BIT_SAMPLE_DISABLE;
	huart2.AdvancedInit.AdvFeatureInit = UART_ADVFEATURE_NO_INIT;
	if (HAL_UART_Init(&huart2) != HAL_OK)
	{
		Error_Handler();
	}
	/* USER CODE BEGIN USART2_Init 2 */

	/* USER CODE END USART2_Init 2 */

}

/**
 * @brief SPI1 Initialization Function
 * @param None
 * @retval None
 */
static void MX_SPI1_Init(void)
{

	/* USER CODE BEGIN SPI1_Init 0 */

	/* USER CODE END SPI1_Init 0 */

	/* USER CODE BEGIN SPI1_Init 1 */

	/* USER CODE END SPI1_Init 1 */
	/* SPI1 parameter configuration*/
	hspi1.Instance = SPI1;
	hspi1.Init.Mode = SPI_MODE_MASTER;
	hspi1.Init.Direction = SPI_DIRECTION_2LINES;
	hspi1.Init.DataSize = SPI_DATASIZE_8BIT;
	hspi1.Init.CLKPolarity = SPI_POLARITY_LOW;
	hspi1.Init.CLKPhase = SPI_PHASE_1EDGE;
	hspi1.Init.NSS = SPI_NSS_HARD_OUTPUT;
	hspi1.Init.BaudRatePrescaler = SPI_BAUDRATEPRESCALER_2;
	hspi1.Init.FirstBit = SPI_FIRSTBIT_MSB;
	hspi1.Init.TIMode = SPI_TIMODE_DISABLE;
	hspi1.Init.CRCCalculation = SPI_CRCCALCULATION_DISABLE;
	hspi1.Init.CRCPolynomial = 7;
	if (HAL_SPI_Init(&hspi1) != HAL_OK)
	{
		Error_Handler();
	}
	/* USER CODE BEGIN SPI1_Init 2 */

	/* USER CODE END SPI1_Init 2 */

}

/**
 * @brief SPI2 Initialization Function
 * @param None
 * @retval None
 */
static void MX_SPI2_Init(void)
{

	/* USER CODE BEGIN SPI2_Init 0 */

	/* USER CODE END SPI2_Init 0 */

	/* USER CODE BEGIN SPI2_Init 1 */

	/* USER CODE END SPI2_Init 1 */
	/* SPI2 parameter configuration*/
	hspi2.Instance = SPI2;
	hspi2.Init.Mode = SPI_MODE_MASTER;
	hspi2.Init.Direction = SPI_DIRECTION_2LINES;
	hspi2.Init.DataSize = SPI_DATASIZE_16BIT;
	hspi2.Init.CLKPolarity = SPI_POLARITY_HIGH;
	hspi2.Init.CLKPhase = SPI_PHASE_1EDGE;
	hspi2.Init.NSS = SPI_NSS_SOFT;
	hspi2.Init.BaudRatePrescaler = SPI_BAUDRATEPRESCALER_16;
	hspi2.Init.FirstBit = SPI_FIRSTBIT_MSB;
	hspi2.Init.TIMode = SPI_TIMODE_DISABLE;
	hspi2.Init.CRCCalculation = SPI_CRCCALCULATION_DISABLE;
	hspi2.Init.CRCPolynomial = 7;
	if (HAL_SPI_Init(&hspi2) != HAL_OK)
	{
		Error_Handler();
	}
	/* USER CODE BEGIN SPI2_Init 2 */

	/* USER CODE END SPI2_Init 2 */

}

/**
 * @brief TIM6 Initialization Function
 * @param None
 * @retval None
 */
static void MX_TIM6_Init(void)
{

	/* USER CODE BEGIN TIM6_Init 0 */

	/* USER CODE END TIM6_Init 0 */

	TIM_MasterConfigTypeDef sMasterConfig = {0};

	/* USER CODE BEGIN TIM6_Init 1 */

	/* USER CODE END TIM6_Init 1 */
	htim6.Instance = TIM6;
	htim6.Init.Prescaler = 4-1;
	htim6.Init.CounterMode = TIM_COUNTERMODE_UP;
	htim6.Init.Period = 1;
	htim6.Init.AutoReloadPreload = TIM_AUTORELOAD_PRELOAD_DISABLE;
	if (HAL_TIM_Base_Init(&htim6) != HAL_OK)
	{
		Error_Handler();
	}
	sMasterConfig.MasterOutputTrigger = TIM_TRGO_RESET;
	sMasterConfig.MasterSlaveMode = TIM_MASTERSLAVEMODE_DISABLE;
	if (HAL_TIMEx_MasterConfigSynchronization(&htim6, &sMasterConfig) != HAL_OK)
	{
		Error_Handler();
	}
	/* USER CODE BEGIN TIM6_Init 2 */

	/* USER CODE END TIM6_Init 2 */

}

/**
 * @brief GPIO Initialization Function
 * @param None
 * @retval None
 */
static void MX_GPIO_Init(void)
{
	GPIO_InitTypeDef GPIO_InitStruct = {0};
	/* USER CODE BEGIN MX_GPIO_Init_1 */
	/* USER CODE END MX_GPIO_Init_1 */

	/* GPIO Ports Clock Enable */
	__HAL_RCC_GPIOC_CLK_ENABLE();
	__HAL_RCC_GPIOH_CLK_ENABLE();
	__HAL_RCC_GPIOA_CLK_ENABLE();
	__HAL_RCC_GPIOB_CLK_ENABLE();

	/*Configure GPIO pin Output Level */
	HAL_GPIO_WritePin(GPIOA, ROUTE_A0_Pin|ROUTE_A1_Pin, GPIO_PIN_RESET);

	/*Configure GPIO pin Output Level */
	HAL_GPIO_WritePin(TX_EN_GPIO_Port, TX_EN_Pin, GPIO_PIN_SET);

	/*Configure GPIO pin Output Level */
	HAL_GPIO_WritePin(GPIOB, IAM_ALIVE_Pin|ADC_CNV_Pin|TEST_SIG_Pin, GPIO_PIN_RESET);

	/*Configure GPIO pins : ROUTE_A0_Pin ROUTE_A1_Pin */
	GPIO_InitStruct.Pin = ROUTE_A0_Pin|ROUTE_A1_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_PULLUP;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

	/*Configure GPIO pins : TX_EN_Pin IAM_ALIVE_Pin ADC_CNV_Pin */
	GPIO_InitStruct.Pin = TX_EN_Pin|IAM_ALIVE_Pin|ADC_CNV_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_PULLUP;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	HAL_GPIO_Init(GPIOB, &GPIO_InitStruct);

	/*Configure GPIO pin : PA8 */
	GPIO_InitStruct.Pin = GPIO_PIN_8;
	GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
	GPIO_InitStruct.Alternate = GPIO_AF0_MCO;
	HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

	/*Configure GPIO pin : TEST_SIG_Pin */
	GPIO_InitStruct.Pin = TEST_SIG_Pin;
	GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
	GPIO_InitStruct.Pull = GPIO_NOPULL;
	GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	HAL_GPIO_Init(TEST_SIG_GPIO_Port, &GPIO_InitStruct);

	/* USER CODE BEGIN MX_GPIO_Init_2 */
	/* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
 * @brief  This function is executed in case of error occurrence.
 * @retval None
 */
void Error_Handler(void)
{
	/* USER CODE BEGIN Error_Handler_Debug */
	/* User can add his own implementation to report the HAL error return state */
	__disable_irq();
	while (1) {
	}
	/* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
 * @brief  Reports the name of the source file and the source line number
 *         where the assert_param error has occurred.
 * @param  file: pointer to the source file name
 * @param  line: assert_param error line source number
 * @retval None
 */
void assert_failed(uint8_t *file, uint32_t line)
{
	/* USER CODE BEGIN 6 */
	/* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
	/* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
