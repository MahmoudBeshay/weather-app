import requests
from flask import Flask, render_template, request

app = Flask(__name__)
app.config['TEMPLATES_AUTO_RELOAD'] = True

def get_location_details(city):
    url = f"https://nominatim.openstreetmap.org/search?city={city}&format=json&limit=1"
    headers = {"User-Agent": "weather-app"}
    response = requests.get(url, headers=headers)

    if response.status_code == 200 and response.json():
        data = response.json()[0]
        address = data.get("address", {})
        state = address.get("state", "")
        country = address.get("country", "")
        return state, country
    return "", ""

@app.route("/", methods=["GET", "POST"])
def weather():
    weather_data = None
    forecast_data = None
    error = None

    if request.method == "POST":
        city = request.form.get("city")
        if city:
            weather_url = f"https://wttr.in/{city}?format=j1"
            try:
                response = requests.get(weather_url)
                response.raise_for_status()
                data = response.json()

                # Get state and country
                state, country = get_location_details(city)

                weather_data = {
                    "city": city,
                    "state": state,
                    "country": country,
                    "temperature": data["current_condition"][0]["temp_C"],
                    "description": data["current_condition"][0]["weatherDesc"][0]["value"],
                    "humidity": data["current_condition"][0]["humidity"],
                    "wind_speed": data["current_condition"][0]["windspeedKmph"]
                }

                # 3-day forecast
                forecast_data = []
                for day in data["weather"]:
                    desc = day["hourly"][4]["weatherDesc"][0]["value"]
                    icon_url = day["hourly"][4]["weatherIconUrl"][0]["value"].replace("//", "https://")

                    forecast_data.append({
                        "date": day["date"],
                        "avgtemp": day["avgtempC"],
                        "desc": desc,
                        "icon": icon_url
                    })

            except Exception as e:
                print("Error fetching weather data:", e)
                error = "City not found or API issue."
        else:
            error = "Please enter a city name."

    return render_template("index.html", weather=weather_data, forecast=forecast_data, error=error)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
# This code is a Flask web application that fetches weather data for a given city.
# It uses the wttr.in API for current weather and a 3-day forecast.