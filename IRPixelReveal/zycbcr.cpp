#include "zycbcr.h"


ZYCbCr::ZYCbCr(float Y, float Cb, float Cr)
{
  this->m_Y=Y;
  this->m_Cb=Cb;
  this->m_Cr=Cr;
}
bool ZYCbCr::isEqual(ZYCbCr pixel)
{
  return ((pixel.m_Y==this->m_Y) && (pixel.m_Cb==this->m_Cb) && (pixel.m_Cr==this->m_Cr));
}
