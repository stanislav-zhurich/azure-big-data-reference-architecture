package com.azure.bigdata.reference.function;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.HttpMethod;
import com.microsoft.azure.functions.HttpRequestMessage;
import com.microsoft.azure.functions.HttpResponseMessage;
import com.microsoft.azure.functions.HttpStatus;
import com.microsoft.azure.functions.annotation.AuthorizationLevel;
import com.microsoft.azure.functions.annotation.EventHubOutput;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.azure.functions.annotation.HttpTrigger;
import com.microsoft.azure.functions.annotation.TimerTrigger;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.util.Optional;

/**
 * Azure Functions with HTTP Trigger.
 */
public class ObservationGeneratorFunction {

    @FunctionName("EventGenerator")
    @EventHubOutput(name = "event", eventHubName = "observation-generator-event-hub", connection = "accessPolicy")
    public String sendEvent(
            @TimerTrigger(name = "eventTrigger", schedule = "*/20 * * * * *") String timerInfo,
            ExecutionContext context) {
        // timeInfo is a JSON string, you can deserialize it to an object using your
        // favorite JSON library
        context.getLogger().info("Timer is triggered: " + timerInfo);

        try {
            String s = getFileInStringFromResources("/resources/observation-template.json");
            TemplateValuesGenerator.Observation observation = TemplateValuesGenerator.getObservation();
            s = s.replace("{patient_id}", TemplateValuesGenerator.getPersonId())
                .replace("{id}", TemplateValuesGenerator.getId())
                .replace("{systolic_value}", observation.getSystolic().getPressure())
                .replace("{systolic_code}", observation.getSystolic().getCode())
                .replace("{systolic_interpretation}", observation.getSystolic().getInterpretation())
                .replace("{diastolic_value}", observation.getDiastolic().getPressure())
                .replace("{diastolic_code}", observation.getDiastolic().getCode())
                .replace("{diastolic_interpretation}", observation.getDiastolic().getInterpretation());
            context.getLogger().info(s);
            return s;
        } catch (IOException e) {
            context.getLogger().warning(e.getMessage());
            throw new RuntimeException(e);
        } 
    }

    private String getFileInStringFromResources(String pathToResource) throws IOException {
        // this is the path within the jar file
        InputStream input = this.getClass().getResourceAsStream("/observation-template.json");
    
        // here is from inside IDE
        if (input == null) {
            input = this.getClass().getClassLoader().getResourceAsStream(pathToResource);
        }
        String text = new String(input.readAllBytes(), StandardCharsets.UTF_8);
        return text;

    }

}
