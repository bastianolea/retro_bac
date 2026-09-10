# Ejecuta la batería de pruebas de la app. Al no ser un paquete, cargamos
# testthat y corremos los tests del directorio directamente.
# Desde la raíz del proyecto: testthat::test_dir("tests/testthat")
library(testthat)

test_dir("tests/testthat")
