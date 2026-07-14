package com.example.weatherapp.controller;

import com.example.weatherapp.model.WeatherResult;
import com.example.weatherapp.service.WeatherLookupException;
import com.example.weatherapp.service.WeatherService;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class WeatherController {

    private final WeatherService weatherService;

    public WeatherController(WeatherService weatherService) {
        this.weatherService = weatherService;
    }

    @GetMapping("/")
    public String index(Model model) {
        model.addAttribute("city", "");
        return "index";
    }

    @PostMapping("/")
    public String search(@RequestParam(defaultValue = "") String city, Model model) {
        String trimmedCity = city.trim();
        model.addAttribute("city", trimmedCity);

        if (trimmedCity.isEmpty()) {
            model.addAttribute("error", "Please enter a city name.");
            return "index";
        }

        try {
            WeatherResult weather = weatherService.getWeather(trimmedCity);
            model.addAttribute("weather", weather);
        } catch (WeatherLookupException ex) {
            model.addAttribute("error", ex.getMessage());
        }

        return "index";
    }
}
