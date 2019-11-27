void LoaderSetup()
{
  for(int i = 0; i < 4; i++)
    pinMode(loaderPins[i], OUTPUT);
  
  Stepping(1);
}


void Refill(int steps)
{
  Stepping(steps);
}



void Stepping(int n)
{
  if (n > 0)
    for (int i = n; i > 0; i--)
    {
      if (thisStep < 3)
        thisStep++;
      else
        thisStep = 0;
      
      UnitStep(thisStep);
    }
  else
    for (int i = n; i < 0; i++)
    {
      if (thisStep > 0)
        thisStep--;
      else
        thisStep = 3;
      
      UnitStep(thisStep);
    }
  
  Serial.print(n);
  Serial.println(" steps run");
}

void UnitStep(byte index)
{
  // Set the pin specified by "index"
  int level[] = { LOW, LOW, LOW, LOW };
  for(int i = 0; i < 4; i++)
  {
    if(i == index)
      level[3 - i] = HIGH;
    digitalWrite(loaderPins[3 - i], level[3 - i]);
  }
  
  // Keep this output for a while before next step
  delay(loaderStepTime);
  
  // Turn off all pins for reducing heating
  for(int i = 0; i < 4; i++)
    digitalWrite(loaderPins[3 - i], LOW);
}
