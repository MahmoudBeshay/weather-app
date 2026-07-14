package com.example.weatherapp.controller;

import com.example.weatherapp.model.WeatherResult;
import com.example.weatherapp.service.WeatherLookupException;
import com.example.weatherapp.service.WeatherService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(WeatherController.class)
class WeatherControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private WeatherService weatherService;

    @Test
    void getIndex_rendersEmptyForm() throws Exception {
        mockMvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Weather")));
    }

    @Test
    void postIndex_withValidCity_showsWeather() throws Exception {
        WeatherResult result = new WeatherResult(
                "London", "United Kingdom", "18", "17", "Partly cloudy", "60", "12");
        when(weatherService.getWeather("London")).thenReturn(result);

        mockMvc.perform(post("/").param("city", "London"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("London")))
                .andExpect(content().string(containsString("Partly cloudy")));
    }

    @Test
    void postIndex_withUnknownCity_showsError() throws Exception {
        when(weatherService.getWeather("Nowhereville"))
                .thenThrow(new WeatherLookupException("City \"Nowhereville\" was not found."));

        mockMvc.perform(post("/").param("city", "Nowhereville"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("was not found")));
    }

    @Test
    void postIndex_withEmptyCity_showsValidationError() throws Exception {
        mockMvc.perform(post("/").param("city", ""))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("Please enter a city name.")));
    }
}
