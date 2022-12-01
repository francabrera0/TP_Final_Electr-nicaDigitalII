#include <Wire.h> 
#include <LiquidCrystal_I2C.h>
LiquidCrystal_I2C lcd(0x27,16,2);  // set the LCD address to 0x27 for a 16 chars and 2 line display

String password="";
String activeWord="";
String triggerWord="0000";
bool flagPass=false;
bool flagWord=false;
bool isActive=false;
bool flag=false;
bool trigger=false;

void setup() {
  Serial.begin(9600);
  Serial.setTimeout(50);
  pinMode(LED_BUILTIN, OUTPUT);

  lcd.init();                      // initialize the lcd 
  lcd.init();
  // Print a message to the LCD.
  lcd.backlight();
  lcd.setCursor(0,0);
  lcd.print("Alarma Pic16F887");
  delay(1000);
  lcd.clear();
}

String read(){
  int i=0;
  int msg[4];
  while(true){
    flag=false;
    if(Serial.available()){
      msg[i] = Serial.read();
      i++;
      if(i==4){
        return String(msg[0],HEX)+String(msg[1],HEX)+String(msg[2],HEX)+String(msg[3],HEX);
      }      
    }
  }
}


void loop() {  
  
  if(!flagPass){
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Please, enter a ");
    lcd.setCursor(0,1);
    lcd.print("password        ");
    password=read();
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Password set    ");
    lcd.setCursor(0,1);
    lcd.print(password);
    flagPass=true;
    delay(1500);
  }
  
  if(!flagWord){
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Please, enter a ");
    lcd.setCursor(0,1);
    lcd.print("keyword         ");
    activeWord=read();
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Keyword set     ");
    lcd.setCursor(0,1);
    lcd.print(activeWord);
    flagWord=true;
    delay(1000); 
  }
/////////////////////////////////////////////////////////begin///////////////////////////////////////////

  while(!isActive){
    delay(100);
    lcd.clear();
    lcd.setCursor(0,0);
    lcd.print("Alarm off       ");
    
    String pass = read();
    
    if(pass==activeWord){
        lcd.clear();
        lcd.setCursor(0,1);
        lcd.print("      Activating");
        delay(1000);
        isActive=true;
        digitalWrite(LED_BUILTIN,HIGH);
     }
     else{
        lcd.setCursor(0,1);
        lcd.print("Wrong keyword   ");
        delay(1000);
        lcd.setCursor(0,1);
        lcd.print("                ");
    }
  }
   

  while(isActive){
    if(!trigger){
      delay(100);
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print("Alarm on        ");
    }

    String pass =read();

    if(pass==password && isActive){
      lcd.clear();
      lcd.setCursor(0,1);
      lcd.print("    Deactivating");
      delay(1000);
      isActive=false;
      trigger=false;
      digitalWrite(LED_BUILTIN,LOW);
    }
    else if(pass==triggerWord){
      lcd.clear();
      lcd.setCursor(0,0);
      lcd.print("Alarm ringin!!  ");
      trigger=true;
    }
    else{
      lcd.setCursor(0,1);
      lcd.print("Wrong password  ");
      delay(1000);
      lcd.setCursor(0,1);
      lcd.print("              ");   
    }

  }     
}

  
