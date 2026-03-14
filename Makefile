
run:
	swift run NowCoinerApp

run-after-build:
	./scripts/package_app.sh
	open ~/Downloads/NowCoiner.app

icon:
	./scripts/generate_app_icon.sh "$(SOURCE)" Sources/NowCoinerApp/Resources

package:
	./scripts/package_app.sh

preflight:
	./scripts/release_preflight.sh

release: package
	./scripts/release_notarize.sh

mas-release: package
	./scripts/release_mas.sh

.PHONY: run run-after-build icon package preflight release mas-release
