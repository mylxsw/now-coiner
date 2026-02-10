
run:
	swift run NowCoinerApp

icon:
	./scripts/generate_app_icon.sh "$(SOURCE)" Sources/NowCoinerApp/Resources

package:
	./scripts/package_app.sh

.PHONY: run icon package
