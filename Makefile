
run:
	swift run NowCoinerApp

icon:
	./scripts/generate_app_icon.sh "$(SOURCE)" Sources/NowCoinerApp/Resources

package:
	./scripts/package_app.sh

preflight:
	./scripts/release_preflight.sh

release:
	./scripts/release_notarize.sh

.PHONY: run icon package preflight release
