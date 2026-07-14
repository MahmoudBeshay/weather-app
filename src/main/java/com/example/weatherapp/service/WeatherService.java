package com.example.weatherapp.service;

import com.example.weatherapp.model.WeatherResult;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Service
public class WeatherService {

    private static final String WTTR_URL = "https://wttr.in/{city}?format=j1";

    private final RestClient restClient;

    public WeatherService(RestClient restClient) {
        this.restClient = restClient;
    }

    public WeatherResult getWeather(String city) {
        JsonNode body;
        try {
            body = restClient.get()
                    .uri(WTTR_URL, city)
                    .retrieve()
                    .body(JsonNode.class);
        } catch (HttpStatusCodeException ex) {
            throw new WeatherLookupException("City \"" + city + "\" was not found.");
        } catch (RestClientException ex) {
            throw new WeatherLookupException("Could not reach the weather service. Try again later.");
        }

        if (body == null) {
            throw new WeatherLookupException("City \"" + city + "\" was not found.");
        }

        JsonNode currentArr = body.path("current_condition");
        JsonNode areaArr = body.path("nearest_area");
        if (!currentArr.isArray() || currentArr.isEmpty() || !areaArr.isArray() || areaArr.isEmpty()) {
            throw new WeatherLookupException("City \"" + city + "\" was not found.");
        }

        JsonNode current = currentArr.get(0);
        JsonNode area = areaArr.get(0);

        String cityName = firstValue(area, "areaName");
        String country = firstValue(area, "country");
        String description = firstValue(current, "weatherDesc");
        String temp = current.path("temp_C").asText("");
        String feelsLike = current.path("FeelsLikeC").asText("");
        String humidity = current.path("humidity").asText("");
        String windSpeed = current.path("windspeedKmph").asText("");

        if (cityName.isEmpty() || temp.isEmpty()) {
            throw new WeatherLookupException("City \"" + city + "\" was not found.");
        }

        return new WeatherResult(cityName, country, temp, feelsLike, description, humidity, windSpeed);
    }

    private String firstValue(JsonNode node, String arrayField) {
        JsonNode arr = node.path(arrayField);
        if (arr.isArray() && !arr.isEmpty()) {
            return arr.get(0).path("value").asText("");
        }
        return "";
    }
}
