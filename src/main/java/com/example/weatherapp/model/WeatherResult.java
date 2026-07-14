package com.example.weatherapp.model;

public record WeatherResult(
        String city,
        String country,
        String temp,
        String feelsLike,
        String description,
        String humidity,
        String windSpeed
) {
}
