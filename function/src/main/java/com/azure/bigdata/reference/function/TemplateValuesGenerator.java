package com.azure.bigdata.reference.function;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.UUID;

public class TemplateValuesGenerator {

    private static int LOWEST_SYSTOLIC = 80;
    private static int HIGHEST_SYSTOLIC = 300;
    private static int LOWEST_DIASTOLIC = 50;

    private static List<String> PATIENT_IDS = new ArrayList<>();
    static {
        PATIENT_IDS.add("patient_01_id");
        PATIENT_IDS.add("patient_02_id");
        PATIENT_IDS.add("patient_03_id");
        PATIENT_IDS.add("patient_04_id");
        PATIENT_IDS.add("patient_05_id");
        PATIENT_IDS.add("patient_06_id");
        PATIENT_IDS.add("patient_07_id");
        PATIENT_IDS.add("patient_08_id");
        PATIENT_IDS.add("patient_09_id");
        PATIENT_IDS.add("patient_10_id");
    }

    static class Interpetation{
        private String code;
        private String interpretation;
        private String pressure;
        private Interpetation(String pressure){
            this.pressure = pressure;
        }
        public String getCode() {
            return code;
        }
        public void setCode(String code) {
            this.code = code;
        }
        public String getInterpretation() {
            return interpretation;
        }
        public void setInterpretation(String interpretation) {
            this.interpretation = interpretation;
        }
        public String getPressure() {
            return pressure;
        }
        
        
    }

    static class Observation{
        private Interpetation systolic;
        private Interpetation diastolic;

        private Observation(Interpetation systolic, Interpetation diastolic){
            this.systolic = systolic;
            this.diastolic = diastolic;
        }

        public Interpetation getSystolic() {
            return systolic;
        }

        public Interpetation getDiastolic() {
            return diastolic;
        }
        

    }

    public static Observation getObservation(){
        Random rand = new Random();
        int systolic = rand.nextInt(LOWEST_SYSTOLIC, HIGHEST_SYSTOLIC);
        int diastolic = rand.nextInt(LOWEST_DIASTOLIC, systolic);
        Interpetation systolicInt = new Interpetation(Integer.toString(systolic));
        Interpetation diastolicInt = new Interpetation(Integer.toString(diastolic));
        if(systolic > 270){
            systolicInt.setCode("A");
            systolicInt.setInterpretation("Abnormal");
        }
        else if (systolic > 200){
            systolicInt.setCode("HH");
            systolicInt.setInterpretation("Critical high");
        }
        else if (systolic > 140){
            systolicInt.setCode("H");
            systolicInt.setInterpretation("High");
        }
        else if (systolic > 110){
            systolicInt.setCode("N");
            systolicInt.setInterpretation("Normal");
        }
        else if(systolic > 100){
            systolicInt.setCode("L");
            systolicInt.setInterpretation("Low");
        }
        else {
            systolicInt.setCode("LL");
            systolicInt.setInterpretation("Critical Low");
        }

        //diastolic
        if(diastolic > 230){
            diastolicInt.setCode("A");
            diastolicInt.setInterpretation("Abnormal");
        }
        else if (diastolic > 180){
            diastolicInt.setCode("HH");
            diastolicInt.setInterpretation("Critical high");
        }
        else if (diastolic > 120){
            diastolicInt.setCode("H");
            diastolicInt.setInterpretation("High");
        }
        else if (diastolic > 80){
            diastolicInt.setCode("N");
            diastolicInt.setInterpretation("Normal");
        }
        else if(diastolic > 60){
            diastolicInt.setCode("L");
            diastolicInt.setInterpretation("Low");
        }
        else {
            diastolicInt.setCode("LL");
            diastolicInt.setInterpretation("Critical Low");
        }

        return new Observation(systolicInt, diastolicInt);

    }

    public static String getPersonId(){
        Random rand = new Random();
        int index = rand.nextInt(PATIENT_IDS.size());
        return PATIENT_IDS.get(index);
    }

    public static String getId(){
        UUID uuid = UUID.randomUUID();
        return uuid.toString();
    }

}
