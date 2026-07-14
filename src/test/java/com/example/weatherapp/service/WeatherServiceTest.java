package com.example.weatherapp.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Answers;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class WeatherServiceTest {

    private static final String WTTR_URL = "https://wttr.in/{city}?format=j1";
    private static final String SUCCESS_PAYLOAD = """
            {
              "current_condition": [
                {
                  "temp_C": "18",
                  "FeelsLikeC": "17",
                  "weatherDesc": [{"value": "Partly cloudy"}],
                  "humidity": "60",
                  "windspeedKmph": "12"
                }
              ],
              "nearest_area": [
                {
                  "areaName": [{"value": "London"}],
                  "country": [{"value": "United Kingdom"}]
                }
              ]
            }
            """;

    @Mock(answer = Answers.RETURNS_DEEP_STUBS)
    private RestClient restClient;

    private WeatherService weatherService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @BeforeEach
    void setUp() {
        weatherService = new WeatherService(restClient);
    }

    @Test
    void getWeather_returnsParsedResult_onSuccess() throws Exception {
        JsonNode payload = objectMapper.readTree(SUCCESS_PAYLOAD);
        when(restClient.get().uri(WTTR_URL, "London").retrieve().body(JsonNode.class))
                .thenReturn(payload);

        var weather = weatherService.getWeather("London");

        assertThat(weather.city()).isEqualTo("London");
        assertThat(weather.country()).isEqualTo("United Kingdom");
        assertThat(weather.temp()).isEqualTo("18");
        assertThat(weather.feelsLike()).isEqualTo("17");
        assertThat(weather.description()).isEqualTo("Partly cloudy");
        assertThat(weather.humidity()).isEqualTo("60");
        assertThat(weather.windSpeed()).isEqualTo("12");
    }

    @Test
    void getWeather_throwsNotFound_onNon200Response() {
        when(restClient.get().uri(WTTR_URL, "Nowhereville").retrieve().body(JsonNode.class))
                .thenThrow(HttpClientErrorException.create(
                        HttpStatus.NOT_FOUND, "Not Found", null, null, null));

        assertThatThrownBy(() -> weatherService.getWeather("Nowhereville"))
                .isInstanceOf(WeatherLookupException.class)
                .hasMessageContaining("was not found");
    }

    @Test
    void getWeather_throwsNotFound_onMalformedPayload() throws Exception {
        JsonNode payload = objectMapper.readTree("{}");
        when(restClient.get().uri(WTTR_URL, "Nowhereville").retrieve().body(JsonNode.class))
                .thenReturn(payload);

        assertThatThrownBy(() -> weatherService.getWeather("Nowhereville"))
                .isInstanceOf(WeatherLookupException.class)
                .hasMessageContaining("was not found");
    }

    @Test
    void getWeather_throwsCouldNotReach_onConnectionFailure() {
        when(restClient.get().uri(WTTR_URL, "London").retrieve().body(JsonNode.class))
                .thenThrow(new ResourceAccessException("Connection refused"));

        assertThatThrownBy(() -> weatherService.getWeather("London"))
                .isInstanceOf(WeatherLookupException.class)
                .hasMessageContaining("Could not reach");
    }
}
