
export const useBackendMode = () => {
    const isBackendMode = useState<boolean>('backend-mode', () => false)

    const toggleBackendMode = () => {
        isBackendMode.value = !isBackendMode.value
    }

    return {
        isBackendMode,
        toggleBackendMode
    }
}
