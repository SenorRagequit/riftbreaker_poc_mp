TimeOfDayPreset
{
	timeofday_sunrise
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.030"
			albedo
			{
				z "0.004"
				x "0.714"
				y "0.192"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.003"
				x "0.715"
				y "0.194"
				w "1.000"
			}

			fog_height "35.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}

		skybox_specular_intensity "0.300"
		physics_gravity_factor "1.000"
		time_of_day "2"
		skybox_diffuse_intensity "0.250"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.283"
			x "1.000"
			y "0.768"
			w "13.455"
		}

		weather_effect
		light_size "0.050"
		fog_params
		{
			end "70.000"
			color
			{
				z "0.012"
				x "0.462"
				y "0.133"
				w "1.000"
			}

			start "40.000"
			density "0.800"
		}

	}

	weather_day
	{
		weather_sound
		time_of_day "0"
		weather_haptic
		weather_effect "effects/weather/magma_biome"
		weather_wind "effects/wind/weak"
		weather_type "0"
	}

	timeofday_day
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.030"
			albedo
			{
				z "0.000"
				x "0.769"
				y "0.016"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.000"
				x "0.769"
				y "0.016"
				w "1.000"
			}

			fog_height "20.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}

		skybox_specular_intensity "0.595"
		physics_gravity_factor "1.000"
		time_of_day "0"
		skybox_diffuse_intensity "0.250"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.147"
			x "0.584"
			y "0.352"
			w "15.091"
		}

		weather_effect
		light_size "0.000"
		fog_params
		{
			end "70.000"
			color
			{
				z "0.000"
				x "0.768"
				y "0.014"
				w "1.000"
			}

			start "38.000"
			density "0.800"
		}

	}

	weather_night
	{
		weather_sound
		time_of_day "2"
		weather_haptic
		weather_effect "effects/weather/magma_biome"
		weather_wind "effects/wind/weak"
		weather_type "0"
	}

	timeofday_night
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.050"
			albedo
			{
				z "0.047"
				x "0.549"
				y "0.094"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.000"
				x "0.095"
				y "0.017"
				w "1.000"
			}

			fog_height "35.000"
			fade_in_distance "50.000"
			fog_density "0.025"
			fade_in_falloff "10.000"
		}

		skybox_specular_intensity "0.100"
		physics_gravity_factor "1.000"
		time_of_day "3"
		skybox_diffuse_intensity "0.250"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.000"
			x "0.000"
			y "0.000"
			w "0.000"
		}

		weather_effect
		light_size "0.200"
		fog_params
		{
			end "70.000"
			color
			{
				z "0.002"
				x "0.223"
				y "0.002"
				w "1.000"
			}

			start "40.000"
			density "0.900"
		}

	}

	timeofday_sunset
	{
		volumetric_fog_params
		{
			fog_height_falloff "0.030"
			albedo
			{
				z "0.095"
				x "0.928"
				y "0.399"
				w "1.000"
			}

			max_distance "100.000"
			scattering_distribution "0.000"
			extinction_scale "0.750"
			emissive
			{
				z "0.094"
				x "0.929"
				y "0.400"
				w "1.000"
			}

			fog_height "20.000"
			fade_in_distance "55.000"
			fog_density "0.025"
			fade_in_falloff "20.000"
		}

		skybox_specular_intensity "0.256"
		physics_gravity_factor "1.000"
		time_of_day "1"
		skybox_diffuse_intensity "0.250"
		clouds_opacity "0.000"
		bloom_params
		light_color
		{
			z "0.102"
			x "0.982"
			y "0.361"
			w "20.000"
		}

		weather_effect
		light_size "0.050"
		fog_params
		{
			end "70.000"
			color
			{
				z "0.031"
				x "0.982"
				y "0.262"
				w "1.000"
			}

			start "40.000"
			density "0.800"
		}

	}

}

