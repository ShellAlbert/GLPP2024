/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
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

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32l0xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define ROUTE_A0_Pin GPIO_PIN_0
#define ROUTE_A0_GPIO_Port GPIOA
#define ROUTE_A1_Pin GPIO_PIN_1
#define ROUTE_A1_GPIO_Port GPIOA
#define TX_EN_Pin GPIO_PIN_0
#define TX_EN_GPIO_Port GPIOB
#define IAM_ALIVE_Pin GPIO_PIN_1
#define IAM_ALIVE_GPIO_Port GPIOB
#define ADC_CNV_Pin GPIO_PIN_12
#define ADC_CNV_GPIO_Port GPIOB
#define TEST_SIG_Pin GPIO_PIN_7
#define TEST_SIG_GPIO_Port GPIOB

/* USER CODE BEGIN Private defines */
extern uint16_t gSPI_Data;
extern uint16_t gSPI_Buffer1[1024];
extern uint16_t gSPI_Buffer2[1024];
extern uint16_t gSPI_RdPtr1;
extern uint16_t gSPI_RdPtr2;
extern uint16_t gSPI_WrPtr1;
extern uint16_t gSPI_WrPtr2;

extern uint16_t gSPI_RxCnt;
extern uint8_t gSPI_RxDone;
extern uint8_t gUART_TxDone;
/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
