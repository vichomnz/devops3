package com.citt.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Info;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(
        info = @Info(
                title = "API Backend Unificado - Despachos y Ventas",
                version = "1.0",
                description = "API REST unificada para gestionar ventas y despachos de productos. Lanzamiento CITT Duoc UC Viña del Mar 2025"
        )
)
public class OpenApiConfig {
}
