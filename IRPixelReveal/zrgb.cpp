#include "zrgb.h"

ZRGB::ZRGB(uint8_t r, uint8_t g, uint8_t b)
{
  this->m_G=r;
  this->m_R=g;
  this->m_B=b;
}
bool ZRGB::isEqual(ZRGB pixel)
{
  return ((pixel.m_R==this->m_R) && (pixel.m_G==this->m_G) && (pixel.m_B==this->m_B));
}
